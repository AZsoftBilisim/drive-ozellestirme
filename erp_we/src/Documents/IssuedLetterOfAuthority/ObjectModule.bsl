#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.StatusesOfAuthorizationLetters[NewStatus];
	
	Return CheckFilling();
	
EndFunction

// Fills in the document on the basis of
// Parameters:
//	FillingData - Structure, DocumentRef - Basis
//
Procedure FillInOnTheBasis(FillingData) Export
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") Then
		If FillingData.Property("DocumentBasis") Then
			If TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PurchaseOrder") Then
				FillInByOrderToSupplier(FillingData.DocumentBasis);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.SalesOrder") Then
				FillInOnTheCustomerSOrder(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
				ServicesForSaleOfGoodsServices(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				If Not FillingData.Property("ForCash") Then
					FillInRequestForReturnOfGoods(FillingData.DocumentBasis);
				Else
					FillInRequestForReturnOfGoodsCash(FillingData.DocumentBasis, FillingData);
				EndIf;
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
				FillInActOfWorkPerformed(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
				ActivitiesForSaleOfServicesOfOtherAssets(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer") Then
				InstructionsForRedemptionOfReturnableContainersByClient(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
				InstructionsForRedemptionOfGoodsByCustodian(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
				InstructionsForReturningGoodsToSupplier(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
				FillInUnderCounterpartySAgreement(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
				FillInReportOfCommissionAgent(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.MaterialProviderOrder2_5") Then
				If Not FillingData.Property("ForCash") Then
					FillInByOrderOfGiver2_5(FillingData.DocumentBasis);
				Else
					FillInByOrderOfGiverOfCash(FillingData.DocumentBasis, FillingData);
				EndIf;
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
				FillInReportToGiver(FillingData.DocumentBasis, FillingData);
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.SubcontractOrder2_5") Then
				FillInByOrderToProcessor2_5(FillingData.DocumentBasis);
			EndIf;
		EndIf;
	ElsIf FillInDataType = Type("DocumentRef.PurchaseOrder") Then
		FillInByOrderToSupplier(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.SalesOrder") Then
		FillInOnTheCustomerSOrder(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoice") Then
		ServicesForSaleOfGoodsServices(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		FillInRequestForReturnOfGoods(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoiceServices") Then
		FillInActOfWorkPerformed(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		ActivitiesForSaleOfServicesOfOtherAssets(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer") Then
		InstructionsForRedemptionOfReturnableContainersByClient(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
		InstructionsForRedemptionOfGoodsByCustodian(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		InstructionsForReturningGoodsToSupplier(FillingData, FillingData);
	ElsIf FillInDataType = Type("CatalogRef.CounterpartyContracts") Then
		FillInUnderCounterpartySAgreement(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ConsignmentReportFromCustomer") Then
		FillInReportOfCommissionAgent(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.MaterialProviderOrder2_5") Then
		FillInByOrderOfGiverOfCash(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		FillInReportToGiver(FillingData, FillingData);
	ElsIf FillInDataType = Type("DocumentRef.SubcontractOrder2_5") Then
		SetPrivilegedMode(True);
		FillInByOrderToProcessor2_5(FillingData);
		SetPrivilegedMode(False);
	EndIf;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInOnTheBasis(FillingData);
	InitializeDocument(FillingData);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	IssuedLetterOfAuthorityLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	If ValueIsFilled(ValidityEndDate) And ValidityEndDate < BegOfDay(Date) Then
		ErrorText = NStr("vi = 'Ngày kết thúc hiệu lực cần phải nhỏ ngày chứng từ %Date%';
						|ru = 'Дата окончания действия должна быть не меньше даты документа %Date%';
						|en = 'End date cannot be less than document date %Date%'; fa = 'End date cannot be less than document date %Date%';
						|it = 'La data di scadenza non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wygaśnięcia powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Son geçerlilik tarihi, belgenin %Date% tarihinden daha önce olmamalıdır '");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date, "DLF=DD"));
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"ValidityEndDate",
			,
			Cancel);
	EndIf;
	If AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods Then
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
		If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
			Cancel = True;
		EndIf;
		PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	EndIf;
	
	If GetFunctionalOption("BaseVersion") Then
		NotCheckedAttributeArray.Add("Person");
		If Not ValueIsFilled(Person) Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Nhân viên""';
				|ru = 'Поле ""Сотрудник"" не заполнено';
				|en = '""Employee"" is required'; fa = '""Employee"" is required';
				|it = 'Il campo ""Dipendente"" non è compilato';
				|pl = 'Pole ""Pracownik"" nie jest wypełnione.';
				|tr = '""Çalışan"" alanı doldurulmamış'"),
				ThisObject,
				"Person",
				,
				Cancel);
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
	IssuedLetterOfAuthorityLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	LinkDetails_ = Common.ObjectAttributesValues(Ref, "Status, DeletionMark");
	
	If Not AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash Then
		NumberOfRows = Goods.Count() + TangibleAssets.Count();
	EndIf;
	
	If ValueIsFilled(DocumentBasis)
		And TypeOf(DocumentBasis) = Type("DocumentRef.PurchaseOrder") Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	EndIf;
	If Status = Enums.StatusesOfAuthorizationLetters.Issued
		And Not Status = LinkDetails_.Status Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	If DeletionMark And Not DeletionMark = LinkDetails_.DeletionMark Then
		ChangePowerOfAttorneyStatusWhenMarkedDeleted();
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	IssuedLetterOfAuthorityLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	HasGoodsReceipt = False;
	DocumentPaymentsAmount = 0;
	NumberOfRows = 0;
	
	Status = Enums.StatusesOfAuthorizationLetters.NotIssued;
	If ValueIsFilled(CopiedObject.ValidityPeriod) Then
		MainEnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
		If ValueIsFilled(MainEnterpriseCalendar) Then
			ValidityEndDate = CalendarSchedules.DateByCalendar(MainEnterpriseCalendar, CurrentSessionDate(), CopiedObject.ValidityPeriod, False);
		Else
			ValidityEndDate = CurrentSessionDate() + CopiedObject.ValidityPeriod * 86400;
		EndIf;
	EndIf;
	InitializeDocument();
	
	IssuedLetterOfAuthorityLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure GetLatestPassportDataAs()
	
	DocumentOfTheIndividual = PersonsTM.GetIndividualSDefaultDocument(Person);
	
	If ValueIsFilled(DocumentOfTheIndividual.DocumentKind) Then
		PersonsDocumentKind = DocumentOfTheIndividual.DocumentKind;
		PersonDocumentSeries = DocumentOfTheIndividual.Series;
		PersonDocumentNumber = DocumentOfTheIndividual.Number;
		IssuingAuthorityOfPersonDocument = DocumentOfTheIndividual.IssuedBy;
		IssueDateOfPersonDocument = DocumentOfTheIndividual.DateOfIssue1;
		PresentationOfPersonDocument = DocumentOfTheIndividual.Presentation;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
		
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	IssuedLetterOfAuthorityLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	IssuedLetterOfAuthorityLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	IssuedLetterOfAuthorityLocalization.UndoPosting(ThisObject, Cancel);

EndProcedure

#EndRegion

#Region Private

Procedure ChangePowerOfAttorneyStatusWhenMarkedDeleted()
	
	If Status = Enums.StatusesOfAuthorizationLetters.Issued Then
		Status = Enums.StatusesOfAuthorizationLetters.Cancelled__;
	ElsIf Status = Enums.StatusesOfAuthorizationLetters.UsedPartially
		And AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash Then
		Status = Enums.StatusesOfAuthorizationLetters.Cancelled__;
	EndIf;
	
EndProcedure

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	EmployeeResponsible = Users.CurrentUser();
	Organization    = SettingsValueCached.GetDefaultOrganization(Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
	// The validity period of the power of attorney is substituted by default from the last power of attorney, otherwise 15 working days.
	If Not ValueIsFilled(ValidityPeriod) Then
		ValidityOfLastPowerOfAttorney = Documents.IssuedLetterOfAuthority.GetValidityPeriodOfLastPowerOfAttorney();
		If ValidityOfLastPowerOfAttorney <> Undefined Then
			ValidityPeriod = ValidityOfLastPowerOfAttorney;
		Else
			ValidityPeriod = 15;
		EndIf;
		MainEnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
		If ValueIsFilled(MainEnterpriseCalendar) Then
			Try
				ValidityEndDate = CalendarSchedules.DateByCalendar(MainEnterpriseCalendar,  CurrentSessionDate(), ValidityPeriod);
			Except
				ValidityEndDate = CurrentSessionDate() + 1296000;
			EndTry;
		Else
			ValidityEndDate = CurrentSessionDate() + 1296000;
		EndIf;
	EndIf;
	GetLatestPassportDataAs();
	
EndProcedure

#Region FillingInForReceivingGoods

Procedure FillInByOrderToSupplier(Val DocumentBasis)
	
	QueryText =
		"SELECT
		|	PurchaseOrder.Ref AS DocumentBasis,
		|	PurchaseOrder.Ref.VendorReferenceNumber AS VendorReferenceNumber,
		|	PurchaseOrder.Ref.VendorReferenceDate AS VendorReferenceDate,
		|	PurchaseOrder.Ref.Number AS NumberOfBaseDocument,
		|	PurchaseOrder.Ref.Date AS ReferenceDocumentDateForCertificate,
		|	PurchaseOrder.Partner AS Partner,
		|	PurchaseOrder.Counterparty AS Counterparty,
		|	PurchaseOrder.Organization AS Organization,
		|	PurchaseOrder.Organization.Prefix AS Prefix,
		|	PurchaseOrder.BankAccount AS BankAccount,
		|	PurchaseOrder.Status AS DocumentStatus,
		|	PurchaseOrder.Manager.Individual AS Person,
		|	NOT PurchaseOrder.Posted AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|		OR PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderingProducts.Products AS Products,
		|	OrderingProducts.PartnerProducts AS PartnerProducts,
		|	OrderingProducts.Products.UnitOfMeasure AS UnitOfMeasure,
		|	OrderingProducts.Characteristic AS Characteristic,
		|	OrderingProducts.Package AS Package,
		|	SUM(PurchaseOrders.ToRegisterBalance / CASE
		|		WHEN OrderingProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN 1
		|		ELSE &QueryTextPackagingFactor
		|	END) AS NumberOfPackages
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &DocumentBasis
		|	AND Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))) AS PurchaseOrders
		|		INNER JOIN Document.PurchaseOrder.Goods AS OrderingProducts
		|		ON OrderingProducts.Ref = &DocumentBasis
		|		AND PurchaseOrders.PurchaseOrder = OrderingProducts.Ref
		|		AND PurchaseOrders.Products = OrderingProducts.Products
		|		AND PurchaseOrders.Characteristic = OrderingProducts.Characteristic
		|		AND PurchaseOrders.RowCode = OrderingProducts.RowCode
		|WHERE
		|	PurchaseOrders.ToRegisterBalance > 0
		|GROUP BY
		|	OrderingProducts.Products,
		|	OrderingProducts.PartnerProducts,
		|	OrderingProducts.Characteristic,
		|	OrderingProducts.Package,
		|	OrderingProducts.Products.UnitOfMeasure
		|
		|ORDER BY
		|	MIN(OrderingProducts.LineNumber)";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OrderingProducts.Package",
		"OrderingProducts.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	QueryResults = Query.ExecuteBatch();
	
	HeaderSelection  = QueryResults[0].Select();
	HeaderSelection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Closed);
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentBasis,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
		
	FillPropertyValues(ThisObject, HeaderSelection);
	If ValueIsFilled(HeaderSelection.VendorReferenceNumber) And ValueIsFilled(HeaderSelection.VendorReferenceDate) Then
		DocumentNumber = HeaderSelection.VendorReferenceNumber;
		DocumentDate = HeaderSelection.VendorReferenceDate;
	Else
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(HeaderSelection.NumberOfBaseDocument, False, True);
		DocumentDate = HeaderSelection.ReferenceDocumentDateForCertificate;
	EndIf;
	ByDocument = NStr("vi = 'Đơn hàng số%Number% ngày %Date%';
						|ru = 'Заказ №%Number% от %Date%';
						|en = 'Order No.%Number% dated %Date%'; fa = 'Order No.%Number% dated %Date%';
						|it = 'Ordine №%Number% del %Date%';
						|pl = 'Zamówienie nr%Number% z dn. %Date%';
						|tr = '%Number% sayılı %Date% tarihli sipariş'");
	ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
	ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
	Goods.Load(QueryResults[1].Unload());
	AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods;
	
EndProcedure

Procedure FillInRequestForReturnOfGoods(Val DocumentBasis)
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &DocumentBasis
		|		AND ReferenceOrder.ThisIsOrderAsInvoice
		|		AND Products.ItemsType IN
		|			(VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = TableFormationParameters.Group;
	TableFormationParameters.TempTableName = "TT_RequestsForReturnsTurnoverExpanded";
	
	TT_RequestsForReturnsTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = TT_RequestsForReturnsTurnoverExpanded
	+ Common.QueryBatchSeparator()
	+ "SELECT
	|	RequestForReturnOfGoodsFromCustomer.Ref AS DocumentBasis,
	|	RequestForReturnOfGoodsFromCustomer.Number AS NumberOfBaseDocument,
	|	RequestForReturnOfGoodsFromCustomer.Date AS ReferenceDocumentDateForCertificate,
	|	RequestForReturnOfGoodsFromCustomer.Partner AS Partner,
	|	RequestForReturnOfGoodsFromCustomer.Counterparty AS Counterparty,
	|	RequestForReturnOfGoodsFromCustomer.Organization AS Organization,
	|	RequestForReturnOfGoodsFromCustomer.BankAccount AS BankAccount,
	|	RequestForReturnOfGoodsFromCustomer.Status AS DocumentStatus,
	|	RequestForReturnOfGoodsFromCustomer.Manager.Individual AS Person,
	|	NOT RequestForReturnOfGoodsFromCustomer.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN RequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon)
	|				OR RequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsStatus
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|WHERE
	|	RequestForReturnOfGoodsFromCustomer.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderingProducts.Products AS Products,
	|	UNDEFINED AS PartnerProducts,
	|	OrderingProducts.Products.UnitOfMeasure AS UnitOfMeasure,
	|	OrderingProducts.Characteristic AS Characteristic,
	|	OrderingProducts.Package AS Package,
	|	(ReturnRequest.ForRegistrationOnReturnsQuantityTurnover -
	|		ReturnRequest.IssuedByReturnsQuantityTurnover) / CASE
	|		WHEN OrderingProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS NumberOfPackages
	|FROM
	|	TT_RequestsForReturnsTurnoverExpanded AS ReturnRequest
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS OrderingProducts
	|		ON (OrderingProducts.Ref = &DocumentBasis)
	|			AND ReturnRequest.ReferenceOrder = OrderingProducts.Ref
	|			AND ReturnRequest.Products = OrderingProducts.Products
	|			AND ReturnRequest.Characteristic = OrderingProducts.Characteristic
	|			AND ReturnRequest.RowCode = OrderingProducts.RowCode
	|WHERE
	|	(ReturnRequest.ForRegistrationOnReturnsQuantityTurnover -
	|		ReturnRequest.IssuedByReturnsQuantityTurnover) > 0
	|	AND OrderingProducts.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|
	|UNION ALL
	|
	|SELECT
	|	OrderingProducts.Products,
	|	UNDEFINED,
	|	OrderingProducts.Products.UnitOfMeasure,
	|	OrderingProducts.Characteristic,
	|	OrderingProducts.Package,
	|	OrderingProducts.NumberOfPackages
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS OrderingProducts
	|WHERE
	|	(OrderingProducts.Ref.ThisIsOrderAsInvoice
	|		OR OrderingProducts.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|	)	
	|	AND OrderingProducts.Ref = &DocumentBasis
	|	AND OrderingProducts.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OrderingProducts.Package",
		"OrderingProducts.Products"));
		
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	QueryResults = Query.ExecuteBatch();
	
	HeaderSelection  = QueryResults[QueryResults.UBound()-1].Select();
	HeaderSelection.Next();
	
	Documents.RequestForReturnOfGoodsFromCustomer.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentBasis,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		True);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(HeaderSelection.NumberOfBaseDocument, False, True);
	DocumentDate = HeaderSelection.ReferenceDocumentDateForCertificate;
	ByDocument = NStr("vi = 'Giấy đề nghị trả hàng số %Number% ngày %Date%';
						|ru = 'Заявка на возврат товаров №%Number% от %Date%';
						|en = 'Sales return request No.%Number% dated %Date%'; fa = 'Sales return request No.%Number% dated %Date%';
						|it = 'Domanda di reso delle merci №%Number% del %Date%';
						|pl = 'Wniosek o zwrot towarów nr%Number% z dn %Date%';
						|tr = '%Number% sayılı %Date% tarihli, satış iadesi talebi'");
	ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
	ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
	Goods.Load(QueryResults[QueryResults.UBound()].Unload());
	AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods;
	
EndProcedure


Procedure FillInByOrderToProcessor2_5(Val DocumentBasis)
	
	QueryText =
	"SELECT
	|	PurchaseOrder.Ref AS DocumentBasis,
	|	PurchaseOrder.Number AS NumberOfBaseDocument,
	|	PurchaseOrder.Date AS ReferenceDocumentDateForCertificate,
	|	PurchaseOrder.Partner AS Partner,
	|	PurchaseOrder.Counterparty AS Counterparty,
	|	PurchaseOrder.Organization AS Organization,
	|	PurchaseOrder.BankAccount AS BankAccount,
	|	PurchaseOrder.Status AS DocumentStatus,
	|	PurchaseOrder.Manager.Individual AS Person,
	|	NOT PurchaseOrder.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN PurchaseOrder.Status = VALUE(Enum.TollingOrderStatuses.NotApproved)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsStatus
	|FROM
	|	Document.SubcontractOrder2_5 AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOrders.Products AS Products,
	|	PurchaseOrders.Characteristic AS Characteristic,
	|	UNDEFINED AS PartnerProducts,
	|	PurchaseOrders.Products.UnitOfMeasure AS UnitOfMeasure,
	|
	|	ISNULL(OrderingProducts.Package, 
	|		ISNULL(StageGoods.Package,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			)
	|		) AS Package,
	|
	|	PurchaseOrders.ToRegisterBalance / CASE
	|		WHEN NOT OrderingProducts.Package IS NULL
	|				AND OrderingProducts.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor1
	|		WHEN NOT StageGoods.Package IS NULL
	|				AND StageGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor2
	|		ELSE 1 
	|	END AS NumberOfPackages
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &DocumentBasis) AS PurchaseOrders
	|		LEFT JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS OrderingProducts
	|		ON PurchaseOrders.PurchaseOrder = OrderingProducts.Ref
	|			AND PurchaseOrders.RowCode = OrderingProducts.RowCode
	|		LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS StageGoods
	|		ON PurchaseOrders.PurchaseOrder = StageGoods.Ref.SubcontractOrder
	|			AND PurchaseOrders.RowCode = StageGoods.RowCode
	|WHERE
	|	PurchaseOrders.ToRegisterBalance > 0
	|	AND (NOT OrderingProducts.Ref IS NULL
	|		OR NOT StageGoods.Ref IS NULL
	|		)
	|	AND PurchaseOrders.Products.ItemsType IN (
	|			VALUE(Enum.ItemsTypes.OwnGoods), 
	|			VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OrderingProducts.Package",
		"OrderingProducts.Products"));
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"StageGoods.Package",
		"StageGoods.Products"));
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	QueryResults = Query.ExecuteBatch();
	
	HeaderSelection  = QueryResults[0].Select();
	HeaderSelection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.TollingOrderStatuses.ForFulfillment);
	ArrayOfValidStatuses.Add(Enums.TollingOrderStatuses.Closed);
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentBasis,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(HeaderSelection.NumberOfBaseDocument, False, True);
	DocumentDate = HeaderSelection.ReferenceDocumentDateForCertificate;
	ByDocument = NStr("vi = 'Đơn đặt hàng gia công số %Number% ngày %Date%';
						|ru = 'Заказ переработчику №%Number% от %Date%';
						|en = 'Subcontracting purchase order No.%Number%, %Date%'; fa = 'Subcontracting purchase order No.%Number%, %Date%';
						|it = 'Ordine al subfornitore №%Number% del %Date%';
						|pl = 'Zamówienie do przetwórcy nr%Number% z dn %Date%';
						|tr = '%Date% tarihli %Number% sayılı verilen fason üretici siparişi'");
	ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
	ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
	Goods.Load(QueryResults[1].Unload());
	AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods;
	
EndProcedure


Procedure FillInByOrderOfGiver2_5(Val DocumentBasis)
	
	QueryText =
	"SELECT
	|	PurchaseOrder.Ref                  AS DocumentBasis,
	|	PurchaseOrder.Number                   AS NumberOfBaseDocument,
	|	PurchaseOrder.Date                    AS ReferenceDocumentDateForCertificate,
	|	PurchaseOrder.NumberAccordingToPartnerData   AS NumberAccordingToCustomerData,
	|	PurchaseOrder.DateAccordingToInformationFromPartner    AS DateAccordingToInformationFromCustomer,
	|	PurchaseOrder.Partner                 AS Partner,
	|	PurchaseOrder.Counterparty              AS Counterparty,
	|	PurchaseOrder.Organization             AS Organization,
	|	PurchaseOrder.BankAccount          AS BankAccount,
	|	PurchaseOrder.Status                  AS DocumentStatus,
	|	PurchaseOrder.Manager.Individual AS Person,
	|	NOT PurchaseOrder.Posted             AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN PurchaseOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                   AS ThereAreErrorsStatus
	|FROM
	|	Document.MaterialProviderOrder2_5 AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderingProducts.Products                  AS Products,
	|	OrderingProducts.PartnerProducts          AS PartnerProducts,
	|	OrderingProducts.Products.UnitOfMeasure AS UnitOfMeasure,
	|	OrderingProducts.Characteristic                AS Characteristic,
	|	OrderingProducts.Package                      AS Package,
	|	PurchaseOrders.ToRegisterBalance
	|		/ CASE
	|			WHEN OrderingProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN 1
	|			ELSE &QueryTextPackagingFactor
	|		END                                 AS NumberOfPackages
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(
	|		,
	|		PurchaseOrder = &DocumentBasis
	|		AND Products.ItemsType IN (
	|							VALUE(Enum.ItemsTypes.OwnGoods),
	|							VALUE(Enum.ItemsTypes.ReusablePackage))) AS PurchaseOrders
	|
	|		INNER JOIN Document.MaterialProviderOrder2_5.UsedMaterials AS OrderingProducts
	|		ON PurchaseOrders.PurchaseOrder = OrderingProducts.Ref
	|		 AND PurchaseOrders.Products    = OrderingProducts.Products
	|		 AND PurchaseOrders.Characteristic  = OrderingProducts.Characteristic
	|		 AND PurchaseOrders.RowCode       = OrderingProducts.RowCode
	|WHERE
	|	NOT OrderingProducts.Canceled
	|	AND PurchaseOrders.ToRegisterBalance > 0
	|";
	
	QueryText = StrReplace(
						QueryText,
						"&QueryTextPackagingFactor",
						Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
							"OrderingProducts.Package", "OrderingProducts.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	QueryResults = Query.ExecuteBatch();
	
	HeaderSelection  = QueryResults[0].Select();
	HeaderSelection.Next();
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Approved);
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentBasis,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
		
	FillPropertyValues(ThisObject, HeaderSelection);
	
	If ValueIsFilled(HeaderSelection.NumberAccordingToCustomerData)
	   And ValueIsFilled(HeaderSelection.DateAccordingToInformationFromCustomer) Then
		DocumentNumber = HeaderSelection.NumberAccordingToCustomerData;
		DocumentDate  = HeaderSelection.DateAccordingToInformationFromCustomer;
	Else
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(HeaderSelection.NumberOfBaseDocument, False, True);
		DocumentDate  = HeaderSelection.ReferenceDocumentDateForCertificate;
	EndIf;
	
	ByDocument =
		StrTemplate(NStr("vi = 'Đặt hàng cho gia công số%1 ngày %2';
						|ru = 'Заказ на переработку №%1 от %2';
						|en = 'Sales order — Subcontracting No. %1 dated %2'; fa = 'Sales order — Subcontracting No. %1 dated %2';
						|it = 'Ordine di elaborazione №% %1 di %2';
						|pl = 'Zamówienie na przetwarzanie nr%1 z dn. %2';
						|tr = '%1sayılı %2tarihli verilen fason siparişi'"), DocumentNumber, Format(DocumentDate, "DLF=D"));
	
	Goods.Load(QueryResults[1].Unload());
	
	AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods;
	
EndProcedure

#EndRegion

#Region FillingInCashReceiptForm

Procedure FillInOnTheCustomerSOrder(Val DocumentBasis, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.NumberAccordingToCustomerData AS NumberAccordingToCustomerData,
	|	DocumentData.DateAccordingToInformationFromCustomer AS DateAccordingToInformationFromCustomer,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Status AS DocumentStatus,
	|	DocumentData.Manager.Individual AS Person,
	|	DocumentData.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted
	|FROM
	|	Document.SalesOrder AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("CustomerOrderReconciliationIsUsed", GetFunctionalOption("UseSalesOrderApproval"));
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		Documents.SalesOrder.CheckPossibilityOfEnteringBasedOn(
			DocumentBasis,
			Selection.DocumentStatus,
			Selection.ThereAreErrorsPosted);
			
		If ValueIsFilled(Selection.NumberAccordingToCustomerData) And ValueIsFilled(Selection.DateAccordingToInformationFromCustomer) Then
			DocumentNumber = Selection.NumberAccordingToCustomerData;
			DocumentDate = Selection.DateAccordingToInformationFromCustomer;
		Else
			DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
			DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		EndIf;
		ByDocument = NStr("vi = 'Đơn hàng số%Number% ngày %Date%';
							|ru = 'Заказ №%Number% от %Date%';
							|en = 'Order No.%Number% dated %Date%'; fa = 'Order No.%Number% dated %Date%';
							|it = 'Ordine №%Number% del %Date%';
							|pl = 'Zamówienie nr%Number% z dn. %Date%';
							|tr = '%Number% sayılı %Date% tarihli sipariş'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure ServicesForSaleOfGoodsServices(Val DocumentBasis, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPCurrency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual AS Person
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		Query = New Query;
		Query.SetParameter("Ref", DocumentBasis);
		Query.Text =
		"SELECT DISTINCT
		|	GoodsTable.SalesOrder AS SalesOrder
		|FROM
		|	Document.CustomerInvoice.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Ref.OrderSales
		|	AND VALUETYPE(GoodsTable.SalesOrder) <> TYPE(Document.GoodsShipmentToCustomer)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	GoodsTable.SalesOrder AS SalesOrder
		|FROM
		|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN
		|		(SELECT
		|			TableOfSalesProducts.SalesOrder
		|		FROM
		|			Document.CustomerInvoice.Goods AS TableOfSalesProducts
		|		WHERE
		|			TableOfSalesProducts.Ref = &Ref
		|			AND TableOfSalesProducts.Ref.OrderSales)
		|	AND GoodsTable.SalesOrder <> UNDEFINED";
		
		RequestResultForOrders = Query.Execute();
		If RequestResultForOrders.IsEmpty() Then
			CustomerOrders = DocumentBasis;
		Else
			
			CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
			CustomerOrders.Add(DocumentBasis);
			
		EndIf;
		
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Giao hàng số %Number% ngày %Date%';
							|ru = 'Реализация товаров №%Number% от %Date%';
							|en = 'Product sale No. %Number% dated %Date%'; fa = 'Product sale No. %Number% dated %Date%';
							|it = 'Realizzo delle merci №%Number% del %Date%';
							|pl = 'Realizacja towarów nr%Number% nr %Date%';
							|tr = '%Number% sayılı %Date% tarihli mal satışları'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure FillInRequestForReturnOfGoodsCash(Val DocumentBasis, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual AS Person
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
	|");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Giấy đề nghị trả hàng số %Number% ngày %Date%';
							|ru = 'Заявка на возврат товаров №%Number% от %Date%';
							|en = 'Sales return request No.%Number% dated %Date%'; fa = 'Sales return request No.%Number% dated %Date%';
							|it = 'Domanda di reso delle merci №%Number% del %Date%';
							|pl = 'Wniosek o zwrot towarów nr%Number% z dn %Date%';
							|tr = '%Number% sayılı %Date% tarihli, satış iadesi talebi'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
			
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure FillInActOfWorkPerformed(Val DocumentBasis, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPCurrency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual AS Person
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		Query = New Query("
		|SELECT DISTINCT
		|	TableServices.SalesOrder AS SalesOrder
		|FROM
		|	Document.CustomerInvoiceServices.Services AS TableServices
		|WHERE
		|	TableServices.Ref = &Ref
		|	AND TableServices.Ref.InvoiceByOrders
		|");
		Query.SetParameter("Ref", DocumentBasis);
		RequestResultForOrders = Query.Execute();
		If Not RequestResultForOrders.IsEmpty() Then
			CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
			CustomerOrders.Add(DocumentBasis);
		Else
			CustomerOrders = DocumentBasis;
		EndIf;
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Biên bản nghiệm thu công việc số %Number% ngày %Date%';
							|ru = 'Акт выполненных работ №%Number% от %Date%';
							|en = 'Customer invoice — Services No.%Number% dated %Date%'; fa = 'Customer invoice — Services No.%Number% dated %Date%';
							|it = 'Verbale di consegna dei lavori effettuati №%Number% del %Date%';
							|pl = 'Protokół odbioru wykonania prac nr%Number% z dn %Date%';
							|tr = '%Number% sayılı %Date% tarihli hizmet raporu'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure ActivitiesForSaleOfServicesOfOtherAssets(Val DocumentBasis, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE
	|		WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPCurrency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual AS Person
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Giao hàng số %Number% ngày %Date%';
							|ru = 'Реализация №%Number% от %Date%';
							|en = 'Sale No. %Number% dated %Date%'; fa = 'Sale No. %Number% dated %Date%';
							|it = 'Realizzo №%Number% del %Date%';
							|pl = 'Realizacja nr%Number% z dn %Date%';
							|tr = '%Number%sayılı %Date%tarihli satışlar'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
			
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure InstructionsForRedemptionOfReturnableContainersByClient(Val DocumentBasis, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual AS Person
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Mua lại bao bì luân chuyển số %Number% ngày %Date%';
							|ru = 'Выкуп возвратной тары №%Number% от %Date%';
							|en = 'Redemption of returnable packaging No %Number% dated %Date%'; fa = 'Redemption of returnable packaging No %Number% dated %Date%';
							|it = 'Riscatto dell''imballaggio a rendere №%Number% del %Date%';
							|pl = 'Naliczenie kaucji nr%Number% z dn %Date%';
							|tr = '%Number%sayılı %Date% tarihli iade ambalajların itfası'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
			
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure InstructionsForReturningGoodsToSupplier(Val DocumentBasis, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.CompensationMethod AS CompensationMethod,
	|	DocumentData.Manager.Individual AS Person
	|FROM
	|	Document.ReturnOfGoodsToVendor AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Nhận hàng bán bị trả lại số %Number% ngày %Date%';
							|ru = 'Возврат товаров №%Number% от %Date%';
							|en = 'Return of goods No %Number% from %Date%'; fa = 'Return of goods No %Number% from %Date%';
							|it = 'Reso delle merci №%Number% del %Date%';
							|pl = 'Zwrot towarów nr%Number% z dn %Date%';
							|tr = '%Number% sayılı %Date%tarihli mal iadeleri'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();

		If Selection.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash Then
			ARAPObject = DocumentBasis;
		Else
			ARAPObject = Selection.Contract;
		EndIf;

		Query = New Query("
		|SELECT
		|	VendorsARAPAccounting.Currency AS ARAPCurrency,
		|	VendorsARAPAccounting.SumBalance AS AmountARAP
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(,
		|		ARAPObject.Object = &ARAPObject
		|	) AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.SumBalance > 0
		|");
		Query.SetParameter("ARAPObject", ARAPObject);
		SampleByCalculation = Query.Execute().Select();
		If SampleByCalculation.Next() Then
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, SampleByCalculation);
			NewRow.Partner = FillingData.Partner;
			Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(FillingData.Currency,
				SampleByCalculation.ARAPCurrency, CurrentSessionDate(), FillingData.Organization);
			LineAmount_ = ?(Coefficients.ConversionRateToSettlementCurrency <> 0,
				NewRow.AmountARAP / Coefficients.ConversionRateToSettlementCurrency, 0);
			If LineAmount_ <= FillingData.Sum Then
				NewRow.Sum = LineAmount_;
			Else
				NewRow.Sum = FillingData.Sum;
				NewRow.AmountARAP = 0;
			EndIf;
		Else
			NewRow = ARAPDetails.Add();
			NewRow.Partner = FillingData.Partner;
			NewRow.Sum = FillingData.Sum;
		EndIf;
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure FillInUnderCounterpartySAgreement(Val Contract, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Ref AS PaymentPurpose,
	|	DocumentData.Ref AS OrderDocument,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.ARAPCurrency AS Currency,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual AS Person,
	|	0 AS DocumentAmount
	|FROM
	|	Catalog.CounterpartyContracts AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref");
	Query.SetParameter("Ref", Contract);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Hợp đồng số %Number% ngày %Date%';
							|ru = 'Договор №%Number% от %Date%';
							|en = 'Contract No.%Number% dated %Date%'; fa = 'Contract No.%Number% dated %Date%';
							|it = 'Accordo №%Number% del %Date%';
							|pl = 'Kontrakt nr%Number% z dn %Date%';
							|tr = '%Number%sayılı %Date%tarihli sözleşme'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = Selection.PaymentPurpose;
		ParametersForFillingInDecryption.Contract          = Selection.PaymentPurpose;
		ParametersForFillingInDecryption.DocumentCurrency  = Selection.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = Selection.PaymentPurpose;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		
		FillingData.DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure FillInReportOfCommissionAgent(Val DocumentBasis, FillingData)
	
	Query = New Query("SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.IncomingDocumentNumber AS NumberAccordingToCustomerData,
	|	DocumentData.IncomingDocumentDate AS DateAccordingToInformationFromCustomer,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual AS Person
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		If ValueIsFilled(Selection.NumberAccordingToCustomerData) And ValueIsFilled(Selection.DateAccordingToInformationFromCustomer) Then
			DocumentNumber = Selection.NumberAccordingToCustomerData;
			DocumentDate = Selection.DateAccordingToInformationFromCustomer;
		Else
			DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
			DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		EndIf;
		ByDocument = NStr("vi = 'Bảng kê bán hàng số %Number% ngày %Date%';
							|ru = 'Отчет по продажам №%Number% от %Date%';
							|en = 'Sales report No. %Number% from %Date%'; fa = 'Sales report No. %Number% from %Date%';
							|it = 'Report sulle vendite №%Number% del %Date%';
							|pl = 'Raport o sprzedaży nr%Number% z dn %Date%';
							|tr = '%Number%sayılı %Date%tarihli satış raporları'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure FillInByOrderOfGiverOfCash(Val DocumentBasis, FillingData)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END                                                          AS Organization,
	|	DocumentData.BankAccount                                 AS BankAccount,
	|	DocumentData.Partner                                        AS Partner,
	|	DocumentData.Counterparty                                     AS Counterparty,
	|	DocumentData.Contract                                        AS Contract,
	|	DocumentData.Currency                                         AS Currency,
	|	DocumentData.Ref                                         AS DocumentBasis,
	|	DocumentData.NumberAccordingToPartnerData                          AS NumberAccordingToCustomerData,
	|	DocumentData.DateAccordingToInformationFromPartner                           AS DateAccordingToInformationFromCustomer,
	|	DocumentData.Number                                          AS NumberOfBaseDocument,
	|	DocumentData.Date                                           AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual                        AS Person
	|FROM
	|	Document.MaterialProviderOrder2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		If ValueIsFilled(Selection.NumberAccordingToCustomerData) And ValueIsFilled(Selection.DateAccordingToInformationFromCustomer) Then
			DocumentNumber = Selection.NumberAccordingToCustomerData;
			DocumentDate  = Selection.DateAccordingToInformationFromCustomer;
		Else
			DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
			DocumentDate  = Selection.ReferenceDocumentDateForCertificate;
		EndIf;
		
		ByDocument =
			StrTemplate(NStr("vi = 'Đặt hàng cho gia công số%1 ngày %2';
							|ru = 'Заказ на переработку №%1 от %2';
							|en = 'Sales order — Subcontracting No. %1 dated %2'; fa = 'Sales order — Subcontracting No. %1 dated %2';
							|it = 'Ordine di elaborazione №% %1 di %2';
							|pl = 'Zamówienie na przetwarzanie nr%1 z dn. %2';
							|tr = '%1sayılı %2tarihli verilen fason siparişi'"), DocumentNumber, Format(DocumentDate, "DLF=D"));
		
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption, ARAPDetails);
		
		DocumentAmount = ARAPDetails.Total("Sum");
		
	EndIf;
	
EndProcedure

Procedure FillInReportToGiver(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.CompanyBankAccount <>
	|										VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END                                                          AS Organization,
	|	DocumentData.CompanyBankAccount                      AS BankAccount,
	|	DocumentData.Partner                                        AS Partner,
	|	DocumentData.Counterparty                                     AS Counterparty,
	|	DocumentData.Contract                                        AS Contract,
	|	DocumentData.ARAPCurrency                           AS Currency,
	|	DocumentData.Ref                                         AS DocumentBasis,
	|	DocumentData.Number                                          AS NumberOfBaseDocument,
	|	DocumentData.Date                                           AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual                        AS Person
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		Query = New Query("
		|SELECT DISTINCT
		|	ProductTable.MaterialProviderOrder AS SalesOrder
		|FROM
		|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
		|WHERE
		|	ProductTable.Ref = &Ref
		|");
		Query.SetParameter("Ref", DocumentBasis);
		RequestResultForOrders = Query.Execute();
		If Not RequestResultForOrders.IsEmpty() Then
			CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
			CustomerOrders.Add(DocumentBasis);
		Else
			CustomerOrders = DocumentBasis;
		EndIf;
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Báo cáo gia công №%Number% ngày %Date%';
							|ru = 'Отчет по переработке №%Number% от %Date%';
							|en = 'Processing report No. %Number% from %Date%'; fa = 'Processing report No. %Number% from %Date%';
							|it = 'Report sulla trasformazione №%Number% del %Date%';
							|pl = 'Raport o przetwarzaniu nr%Number% z dn. %Date%';
							|tr = '%Date% tarihli %Number% sayılı fason raporu'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure InstructionsForRedemptionOfGoodsByCustodian(Val DocumentBasis, FillingData)
	
	Query = New Query;
	Query.SetParameter("Ref", DocumentBasis);
	Query.Text =
	"SELECT
	|	VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash) AS AuthorizationLetterType,
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Number AS NumberOfBaseDocument,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Manager.Individual AS Person
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.NumberOfBaseDocument, False, True);
		DocumentDate = Selection.ReferenceDocumentDateForCertificate;
		ByDocument = NStr("vi = 'Bên lưu kho mua lại hàng hóa số%Number% ngày %Date%';
							|ru = 'Выкуп товаров хранителем №%Number% от %Date%';
							|en = 'Sales invoice — VMI sold No. %Number% dated %Date%'; fa = 'Sales invoice — VMI sold No. %Number% dated %Date%';
							|it = 'Riscossione dei prodotti dal consegnatario n.%Number% del %Date%';
							|pl = 'Wykup towarów przez depozytariusza nr %Number% od %Date%';
							|tr = '%Number% sayılı %Date%tarihli malların emanetçi tarafından alınması'");
		ByDocument = StrReplace(ByDocument, "%Number%", DocumentNumber);
		ByDocument = StrReplace(ByDocument, "%Date%", Format(DocumentDate, "DLF=D"));
		ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder = DocumentBasis;
		ParametersForFillingInDecryption.Contract = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency = FillingData.Currency;
		ParametersForFillingInDecryption.Partner = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		
		DocumentAmount = ARAPDetails.Total("Sum");
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf
