
#Region Public

// Checks whether the agreement is currently valid for the partner 
//
// Parameters:
//  Terms - CatalogRef.TermsOfSale - the agreement
//                that is being verified.
//  Partner - CatalogRef.Partners - the partner
//                that the verification is being performed for.
//
// Returns:
//  Boolean    - True if it works, false in the opposite case.
// 
Function AgreementIsValidForPartner(Terms,Partner)  Export
	
	If Terms.IsEmpty() Or Partner.IsEmpty() Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	CustomerTermsOfSales.Ref,
	|	CustomerTermsOfSales.Warehouse,
	|	CustomerTermsOfSales.Currency,
	|	CustomerTermsOfSales.PriceIncludesVAT,
	|	CustomerTermsOfSales.Description,
	|	CustomerTermsOfSales.ContractsAreUsed,
	|	CustomerTermsOfSales.BusinessOperation,
	|	CustomerTermsOfSales.Organization,
	|	CustomerTermsOfSales.ProductSegment,
	|	ISNULL(Warehouses.IsFolder, FALSE) AS ThisIsWarehouseGroup
	|FROM
	|	Catalog.TermsOfSale AS CustomerTermsOfSales
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON CustomerTermsOfSales.Warehouse = Warehouses.Ref
	|WHERE
	|	NOT CustomerTermsOfSales.DeletionMark
	|	AND (CustomerTermsOfSales.ValidityStartDate = DATETIME(1, 1, 1)
	|			OR CustomerTermsOfSales.ValidityStartDate <= &CurrentDate)
	|	AND (CustomerTermsOfSales.ValidityEndDate = DATETIME(1, 1, 1)
	|			OR CustomerTermsOfSales.ValidityEndDate >= &CurrentDate)
	|	AND (CustomerTermsOfSales.Partner = &Partner
	|			OR CustomerTermsOfSales.PartnersSegment IN
	|				(SELECT
	|					SegmentPartners.Segment
	|				FROM
	|					InformationRegister.SegmentPartners AS SegmentPartners
	|				WHERE
	|					SegmentPartners.Partner = &Partner)
	|			OR CustomerTermsOfSales.Standard_
	|				AND CustomerTermsOfSales.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef))
	|	AND CustomerTermsOfSales.Ref = &Terms
	|	AND CustomerTermsOfSales.AvailableToExternalUsers
	|	AND CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)";
	
	Query.SetParameter("CurrentDate",BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Partner",Partner);
	Query.SetParameter("Terms",Terms);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		If Selection.Next() Then
			Return Selection;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Gets the agreement of the partner by default.
//
// Parameters:
//  Partner - CatalogRef.Partners - the partner for whom the agreement is obtained.
//  BusinessOperation - EnumRef.BusinessTransactions - business transaction of the agreement.
//
// Returns:
//  QueryResultSelection, Undefined - contains a link to the agreement and the details of the agreement,
//
Function GetDefaultPartnerAgreement(Partner, BusinessOperation) Export
	
	If Partner.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	CustomerTermsOfSales.Ref,
	|	CustomerTermsOfSales.Standard_,
	|	CustomerTermsOfSales.Currency,
	|	CustomerTermsOfSales.Counterparty,
	|	CustomerTermsOfSales.PaymentMethod,
	|	CustomerTermsOfSales.Warehouse,
	|	CustomerTermsOfSales.ValidityStartDate,
	|	CustomerTermsOfSales.ValidityEndDate,
	|	CustomerTermsOfSales.Description,
	|	CustomerTermsOfSales.Organization,
	|	CustomerTermsOfSales.PriceIncludesVAT,
	|	CustomerTermsOfSales.ContractsAreUsed,
	|	CustomerTermsOfSales.BusinessOperation,
	|	ISNULL(Warehouses.IsFolder, FALSE) AS ThisIsWarehouseGroup
	|INTO AvailableAgreements
	|FROM
	|	Catalog.TermsOfSale AS CustomerTermsOfSales
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON CustomerTermsOfSales.Warehouse = Warehouses.Ref
	|WHERE
	|	NOT CustomerTermsOfSales.DeletionMark
	|	AND CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND (CustomerTermsOfSales.ValidityStartDate = DATETIME(1, 1, 1)
	|			OR CustomerTermsOfSales.ValidityStartDate < &CurrentDate)
	|	AND (CustomerTermsOfSales.ValidityEndDate = DATETIME(1, 1, 1)
	|			OR CustomerTermsOfSales.ValidityEndDate > &CurrentDate)
	|	AND (CustomerTermsOfSales.Partner = &Partner
	|	OR CASE WHEN CustomerTermsOfSales.Standard_ AND CustomerTermsOfSales.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef) THEN TRUE
	|		WHEN CustomerTermsOfSales.PartnersSegment IN
	|			(SELECT
	|				SegmentPartners.Segment
	|			FROM
	|				InformationRegister.SegmentPartners AS SegmentPartners
	|			WHERE
	|				SegmentPartners.Partner = &Partner) THEN TRUE
	|		ELSE FALSE
	|		END
	|			OR &ToUseTermsOfSales = FALSE)
	|	AND CustomerTermsOfSales.AvailableToExternalUsers
	|	AND CASE
	|			WHEN &OnlyStandard = TRUE
	|					AND &OnlyPersonal = FALSE
	|					AND CustomerTermsOfSales.Standard_
	|				THEN TRUE
	|			WHEN &OnlyPersonal = TRUE
	|					AND NOT &OnlyStandard = TRUE
	|					AND NOT CustomerTermsOfSales.Standard_
	|				THEN TRUE
	|			WHEN &OnlyStandard = FALSE
	|					AND &OnlyPersonal = FALSE
	|				THEN TRUE
	|			WHEN &ToUseTermsOfSales = FALSE
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|	AND CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerTermsOfSales.BusinessOperation = &BusinessOperation
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailableAgreements.Standard_ AS Standard_,
	|	COUNT(AvailableAgreements.Standard_) AS Count
	|INTO AvailableTypeConventions
	|FROM
	|	AvailableAgreements AS AvailableAgreements
	|
	|GROUP BY
	|	AvailableAgreements.Standard_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailableTypeConventions.Count
	|INTO Standard3
	|FROM
	|	AvailableTypeConventions AS AvailableTypeConventions
	|WHERE
	|	AvailableTypeConventions.Standard_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailableTypeConventions.Count
	|INTO SpecialTerms
	|FROM
	|	AvailableTypeConventions AS AvailableTypeConventions
	|WHERE
	|	NOT AvailableTypeConventions.Standard_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN NestedQuery.QuantityCustomized = 1
	|			THEN FALSE
	|		WHEN NestedQuery.NumberTypical = 1
	|				AND ISNULL(NestedQuery.QuantityCustomized, 0) = 0
	|			THEN TRUE
	|	END AS Standard_
	|INTO AgreementType
	|FROM
	|	(SELECT TOP 1
	|		NestedQuery.NumberTypical AS NumberTypical,
	|		NestedQuery.QuantityCustomized AS QuantityCustomized
	|	FROM
	|		(SELECT
	|			Standard3.Count AS NumberTypical,
	|			SpecialTerms.Count AS QuantityCustomized
	|		FROM
	|			Standard3 AS Standard3
	|				LEFT JOIN SpecialTerms AS SpecialTerms
	|				ON (TRUE)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Standard3.Count,
	|			SpecialTerms.Count
	|		FROM
	|			SpecialTerms AS SpecialTerms
	|				LEFT JOIN Standard3 AS Standard3
	|				ON (TRUE)) AS NestedQuery) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailableAgreements.Ref,
	|	AvailableAgreements.Currency,
	|	AvailableAgreements.Warehouse,
	|	AvailableAgreements.Counterparty,
	|	AvailableAgreements.PaymentMethod,
	|	AvailableAgreements.PriceIncludesVAT,
	|	AvailableAgreements.Description,
	|	AvailableAgreements.Organization,
	|	AvailableAgreements.ContractsAreUsed,
	|	AvailableAgreements.BusinessOperation,
	|	AvailableAgreements.ThisIsWarehouseGroup,
	|	&Partner AS Partner
	|FROM
	|	AvailableAgreements AS AvailableAgreements
	|		INNER JOIN AgreementType AS AgreementType
	|		ON AvailableAgreements.Standard_ = AgreementType.Standard_";
	
	Query.SetParameter("CurrentDate",CurrentSessionDate());
	Query.SetParameter("Partner",Partner);
	
	UseStandardTermsOfSalesWithCustomers			= GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales	= GetFunctionalOption("UseCustomerTermsOfSales");
	ToUseTermsOfSales                = GetFunctionalOption("ToUseTermsOfSales");
	
	OnlyStandard = UseStandardTermsOfSalesWithCustomers And Not UseCustomerTermsOfSales;
	OnlyPersonal = Not UseStandardTermsOfSalesWithCustomers And UseCustomerTermsOfSales;
	Query.SetParameter("OnlyStandard",OnlyStandard);
	Query.SetParameter("OnlyPersonal",OnlyPersonal);
	Query.SetParameter("ToUseTermsOfSales",ToUseTermsOfSales);
	Query.SetParameter("BusinessOperation",BusinessOperation);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		If Selection.Next() Then
			Return Selection;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Gets the main partner Manager
//
// Parameters:
//  Partner  - CatalogRef.Partners - the partner for which we get the value of the main Manager.
//
// Returns:
//   CatalogRef.Users   - the main manager of the partner.
//
Function MainManagerOfPartner(Partner) Export
	
	SetPrivilegedMode(True);
	
	If GetFunctionalOption("UseBusinessRegions") Then
		Query = New Query;
		Query.Text = "
		|SELECT
		|	CASE
		|		WHEN Partners.MainManager <> VALUE(Catalog.Users.EmptyRef)
		|			THEN Partners.MainManager
		|		ELSE ISNULL(BusinessRegions.MainManager, VALUE(Catalog.Users.EmptyRef))
		|	END AS MainManager
		|FROM
		|	Catalog.Partners AS Partners
		|		LEFT JOIN Catalog.BusinessRegions AS BusinessRegions
		|		ON Partners.BusinessRegion = BusinessRegions.Ref
		|WHERE
		|	Partners.Ref = &Partner";
		
		Query.SetParameter("Partner", Partner);
		
		Result = Query.Execute();
		If Result.IsEmpty() Then
			Return Catalogs.Users.EmptyRef();
		Else
			
			Selection = Result.Select();
			Selection.Next();
			Return Selection.MainManager;
			
		EndIf;
		
	Else
		
		Return Common.ObjectAttributeValue(Partner, "MainManager");
		
	EndIf;
	
EndFunction

// Gets the main Manager of the partner's contact person.
//
// Parameters:
//  ContactPerson  - CatalogRef.ContactPersonsForPartners - the contact person of the partner for whom we get the value of the main manager.
//
// Returns:
//   CatalogRef.Users   - the main manager of the partner's contact person.
//
Function PrimaryContactPersonManager(ContactPerson) Export
	
	SetPrivilegedMode(True);
	
	If GetFunctionalOption("UseBusinessRegions") Then
		Query = New Query;
		Query.Text = "
		|SELECT 
		|	CASE
		|		WHEN Partners.MainManager <> VALUE(Catalog.Users.EmptyRef)
		|			THEN Partners.MainManager
		|		ELSE ISNULL(BusinessRegions.MainManager, VALUE(Catalog.Users.EmptyRef))
		|	END AS MainManager
		|FROM
		|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON Partners.Ref = ContactPersonsForPartners.Owner
		|		LEFT JOIN Catalog.BusinessRegions AS BusinessRegions
		|		ON Partners.BusinessRegion = BusinessRegions.Ref
		|WHERE
		|	ContactPersonsForPartners.Ref = &ContactPerson";
		
		Query.SetParameter("ContactPerson", ContactPerson);
		
		Result = Query.Execute();
		If Result.IsEmpty() Then
			Return Catalogs.Users.EmptyRef();
		Else
			
			Selection = Result.Select();
			Selection.Next();
			Return Selection.MainManager;
			
		EndIf;
		
	Else
		
		Query = New Query;
		
		Query.Text = "
		|SELECT
		|	Partners.MainManager AS MainManager
		|FROM
		|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON ContactPersonsForPartners.Owner = Partners.Ref
		|WHERE
		|	ContactPersonsForPartners.Ref = &ContactPerson";
		
		Query.SetParameter("ContactPerson", ContactPerson);
		Result = Query.Execute();
		If Result.IsEmpty() Then
			Return Catalogs.Users.EmptyRef();
		Else
			
			Selection = Result.Select();
			Selection.Next();
			Return Selection.MainManager;
			
		EndIf;

	EndIf;
	
EndFunction

// Gets the main Manager of the external user.
//
// Parameters:
//  ExternalUser  - CatalogRef.ExternalUsers - external user, for which we get the value of the main manager.
//
// Returns:
//   CatalogRef.Users   - the main manager of the external user.
//
Function PrimaryExternalUserManager(ExternalUser) Export
	
	AuthorizationObject = Common.ObjectAttributeValue(ExternalUser, "AuthorizationObject");
	
	If TypeOf(AuthorizationObject) = Type("CatalogRef.Partners") Then
		Return MainManagerOfPartner(AuthorizationObject);
	ElsIf TypeOf(AuthorizationObject) = Type("CatalogRef.ContactPersonsForPartners") Then
		Return PrimaryContactPersonManager(AuthorizationObject);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Gets the default document Manager, depending on the type of authorized user.
//
// Returns:
//   CatalogRef.Users   - the main manager of the external user.
//
Function DefaultDocumentManager() Export
	
	If Users.IsExternalUserSession() Then
		Return PrimaryExternalUserManager(Users.AuthorizedUser());
	Else
		Return Users.CurrentUser();
	EndIf;
	
EndFunction

#EndRegion

#Region Private

#Region AcceptanceCertificateFromClient

Procedure GetUploadedProductsFromStorage(Form, CachedValues ,GoodsAddressInStorage, ThisIsActOfDivergenceAfterShipment, CallAvailabilityManagement = True) Export
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Form.Object);
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	SelfServiceClientServer.AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form.Object);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DataFromExternalSource.Products,
	|	DataFromExternalSource.Characteristic,
	|	DataFromExternalSource.Package,
	|	DataFromExternalSource.NumberOfPackages,
	|	DataFromExternalSource.Price,
	|	DataFromExternalSource.VATRate,
	|	DataFromExternalSource.ItemVariantsAreUsed
	|INTO ExternalSourceData
	|FROM
	|	&DataFromExternalSource AS DataFromExternalSource
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Products,
	|	DocumentData.Characteristic,
	|	DocumentData.Package,
	|	DocumentData.NumberOfPackages,
	|	DocumentData.Price,
	|	DocumentData.LineNumber
	|INTO DocumentData
	|FROM
	|	&DocumentData AS DocumentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalSourceData.Products,
	|	ExternalSourceData.Characteristic,
	|	ExternalSourceData.Package,
	|	ExternalSourceData.NumberOfPackages,
	|	ExternalSourceData.Price,
	|	ISNULL(DocumentData.LineNumber, 0) AS LineNumber,
	|	ExternalSourceData.VATRate,
	|	ExternalSourceData.ItemVariantsAreUsed
	|FROM
	|	ExternalSourceData AS ExternalSourceData
	|		LEFT JOIN DocumentData AS DocumentData
	|		ON ExternalSourceData.Products = DocumentData.Products
	|			AND ExternalSourceData.Characteristic = DocumentData.Characteristic
	|			AND ExternalSourceData.Package = DocumentData.Package
	|			AND ExternalSourceData.Price = DocumentData.Price";
	
	Query.SetParameter("DataFromExternalSource", ItemsFromStorage);
	Query.SetParameter("DocumentData", Form.Object.Goods.Unload());
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	RowsToProcess = New Array();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
	
		If Selection.LineNumber > 0 Then
			
			StringTSGoods = Form.Object.Goods[Selection.LineNumber - 1];
			StringTSGoods.NumberOfPackages = Selection.NumberOfPackages;
			
		Else
			
			StringTSGoods = Form.Object.Goods.Add();
			FillPropertyValues(StringTSGoods, Selection);
			SelfServiceClientServer.FillInDocumentBaseInLine(StringTSGoods,
			                                                               Form.BasisDocuments,
			                                                               ThisIsActOfDivergenceAfterShipment);
		EndIf;
		
		RowsToProcess.Add(StringTSGoods);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Form.Object.Goods,
		CachedValues);
	
	DiscrepanciesServer.FillInServiceDetailsForProductRange(Form.Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Form.Object, Form.SeriesSpecificationParameters);
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	
	If CallAvailabilityManagement Then
		DiscrepanciesClientServer.AvailabilityControl(Form);
	EndIf;
	
EndProcedure

#EndRegion

// Places an order
//
// Parameters:
//  OrderStructure  - Structure - contains information necessary for placing an order.
//  Post  - Boolean - indicates whether the order is required.
//
Procedure RegisterOrder(OrderStructure, Post = True) Export
	
	SetPrivilegedMode(True);
	
	DocumentOrderDocument = Documents.SalesOrder.CreateDocument();
	
	FillPropertyValues(DocumentOrderDocument,OrderStructure);
	DocumentOrderDocument.Status = Enums.SalesOrderStatuses.NotApproved;
	DocumentOrderDocument.Priority = SettingsValueCached.GetDefaultPriority(DocumentOrderDocument.Priority);
	DocumentOrderDocument.DiscountsAreCalculated = True;
	DocumentOrderDocument.Manager = SelfServiceServer.MainManagerOfPartner(OrderStructure.Partner);
	DocumentOrderDocument.ContactPerson = OrderStructure.ContactPerson;
	DocumentOrderDocument.AdditionalInformation = OrderStructure.AdditionalInformation;
	DocumentOrderDocument.Goods.Load(OrderStructure.Goods.Unload());
	
	If DocumentOrderDocument.NotShipInInstallments Then
		For Each LineProducts_ In DocumentOrderDocument.Goods Do
			LineProducts_.DateOfShipment = DocumentOrderDocument.DateOfShipment;
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
			And DocumentOrderDocument.NotShipInInstallments
			And Not ValueIsFilled(DocumentOrderDocument.DateOfShipment) Then
		
		DateOfShipment = CurrentSessionDate();
		For Each LineProducts_ In DocumentOrderDocument.Goods Do
			LineProducts_.DateOfShipment = DateOfShipment;
		EndDo;
		
	EndIf;
	DocumentOrderDocument.DiscountsMarkups.Load(OrderStructure.DiscountsMarkups.Unload());
	
	If OrderStructure.Property("Contract") And ValueIsFilled(OrderStructure.Contract) Then
		
		DocumentOrderDocument.Contract = OrderStructure.Contract;
		Query = New Query;
		Query.Text = "SELECT
		|	CounterpartyContracts.BankAccount,
		|	CounterpartyContracts.CounterpartyBankAccount
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Contract";
		
		Query.SetParameter("Contract",OrderStructure.Contract);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			DocumentOrderDocument.CounterpartyBankAccount = Selection.CounterpartyBankAccount;
			DocumentOrderDocument.BankAccount            = Selection.BankAccount;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(DocumentOrderDocument.Contract) Then
		
		DocumentOrderDocument.ForeignCurrencyTransaction = Common.ObjectAttributeValue(DocumentOrderDocument.Contract,"ForeignCurrencyTransaction");
		
	Else
		
		CurrencyOfPayment = CashServer.GetPaymentCurrency(DocumentOrderDocument.PaymentMethod, DocumentOrderDocument.BankAccount, DocumentOrderDocument.CashAccount);
		DocumentOrderDocument.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency(CurrencyOfPayment, DocumentOrderDocument.Organization);
	
	EndIf;
	
	If ValueIsFilled(DocumentOrderDocument.DeliveryPoint) Then
		
		DocumentOrderDocument.DeliveryZone = Common.ObjectAttributeValue(
			DocumentOrderDocument.DeliveryPoint,
			"DeliveryZone");
		
	EndIf;
	
	PaymentStepsServer.CheckAndFillInPaymentScheduleStages(DocumentOrderDocument);
	
	FillInSeparately = Common.ObjectAttributeValue(DocumentOrderDocument.Terms, "EnableAssigmentSupplyForOrders");
	ProvisionInDocumentsServer.FillInDefaultSecurityOption(DocumentOrderDocument.Goods, FillInSeparately);
	
	LinesOfBusinessServer.FillInDefaultDirection(DocumentOrderDocument.LineOfBusiness, DocumentOrderDocument.Terms, DocumentOrderDocument.Contract);
	
	DocumentOrderDocument.Write(?(Post, DocumentWriteMode.Posting, DocumentWriteMode.Write));
	
	If Post Then
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	|	CustomerOrderGoods.ProductsInSet,
	|	CustomerOrderGoods.ItemVariantOfSet,
	|	CustomerOrderGoods.Products,
	|	CustomerOrderGoods.Characteristic,
	|	CustomerOrderGoods.Package,
	|	CustomerOrderGoods.NumberOfPackages
	|INTO DocumentData
	|FROM
	|	Document.SalesOrder.Goods AS CustomerOrderGoods
	|WHERE
	|	CustomerOrderGoods.Ref = &OrderDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerShoppingCart.AuthorizationObject,
	|	CustomerShoppingCart.ProductsInSet,
	|	CustomerShoppingCart.ItemVariantOfSet,
	|	CustomerShoppingCart.Products,
	|	CustomerShoppingCart.Characteristic,
	|	CustomerShoppingCart.Package,
	|	CustomerShoppingCart.NumberOfPackages,
	|	CustomerShoppingCart.Price,
	|	CustomerShoppingCart.PutFileDate,
	|	CustomerShoppingCart.Currency
	|FROM
	|	InformationRegister.CustomerShoppingCart AS CustomerShoppingCart
	|		LEFT JOIN DocumentData AS DocumentData
	|		ON CustomerShoppingCart.Products = DocumentData.Products
	|			AND CustomerShoppingCart.Characteristic = DocumentData.Characteristic
	|			AND CustomerShoppingCart.Package = DocumentData.Package
	|WHERE
	|	CustomerShoppingCart.AuthorizationObject = &AuthorizationObject
	|	AND DocumentData.NumberOfPackages IS NULL ";
	
	Query.SetParameter("AuthorizationObject",OrderStructure.AuthorizationObject);
	Query.SetParameter("OrderDocument",DocumentOrderDocument.Ref);
	
	RecordSet = InformationRegisters.CustomerShoppingCart.CreateRecordSet();
	RecordSet.Filter.AuthorizationObject.Set(OrderStructure.AuthorizationObject, True);
	RecordSet.Load(Query.Execute().Unload());
	RecordSet.Write();
	
EndProcedure

// Records the partner's contact information
//
// Parameters:
//  Partner					- CatalogRef.Partners - partner for whom contact information is recorded
//  ContactInformation	- ValueTable - contains a new value for the partner's contact information.
//
Procedure RecordPartnerContactInformation(Partner, ContactInformation) Export
	
	SetPrivilegedMode(True);
	
	PartnerObject = Partner.GetObject();
	PartnerObject.ContactInformation.Load(ContactInformation);
	PartnerObject.Write();
	
EndProcedure

// Retrieves the metadata object attachment table for output to the object form
//
//Parameters:
//  Owner  - DocumentRef     - the metadata object is the owner of the attached files.
//  GenerateSizePresentation - Boolean - indicates that you need to form a text representation of the file size.
//  SelectByAuthor               - Boolean - indicates whether files created by the current external user should be selected.
//
// Returns:
//  ValueTable   - a table of values containing information about attachments.
//
Function MetadataObjectAttachments(Owner, GenerateSizePresentation = False, SelectByAuthor = True) Export
	
	SetPrivilegedMode(True);
	
	OwnerName = Owner.Metadata().Name;
	FullCatalogNameAttachedFiles = "Catalog." + OwnerName + "AttachedFiles";
	
	If GenerateSizePresentation Then
		TextSizePresentation = ",
		|CAST("""" AS STRING(20)) AS SizePresentation";
	Else
		TextSizePresentation = "";
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Files.Ref,
	|	Files.PictureIndex,
	|	Files.Size AS FileSize,
	|	Files.SignedWithDS,
	|	CASE
	|		WHEN Files.Extension = &IsBlankString
	|			THEN Files.Description
	|		ELSE Files.Description + ""."" + Files.Extension
	|	END AS FileName" + TextSizePresentation + "
	|FROM
	|	" + FullCatalogNameAttachedFiles + " AS Files
	|WHERE
	|	Files.FileOwner = &Owner
	|	AND NOT Files.DeletionMark";

	
	Query.SetParameter("Owner", Owner);
	Query.SetParameter("IsBlankString","");

	
	If SelectByAuthor Then
		Query.Text = Query.Text + "
		|	AND Files.Author = &Author";
		Query.SetParameter("Author", ExternalUsers.CurrentExternalUser());
	EndIf;
	
	If OwnerName = "MailoutToCustomers" Then
		
		Query.Text = Query.Text + "
		|	AND Files.EmailFileID = &IsBlankString";
		Query.SetParameter("IsBlankString", "");
		
	EndIf;
		
	TableForReturn =  Query.Execute().Unload(); // ValueTable
	
	If GenerateSizePresentation Then
		
		For Each TableRow In TableForReturn Do
		
			TableRow.SizePresentation = 
				InteractionsClientServer.GetFileSizeStringPresentation(TableRow.FileSize);
		
		EndDo;
	EndIf;
	
	Return TableForReturn;
	
EndFunction

// Generates an array of possible types of information about product availability for partners.
// Used when determining the maximum status for a group of warehouses.
// The higher the status, the smaller the message sequence number in the array.
//
//
// Returns:
//   Array of String - the generated array.
//
Function ArrayOfAccessibilityTexts() Export
	
	Array = New Array;
	Array.Add(NStr("vi = 'Có sẵn';
					|ru = 'В наличии';
					|en = 'In stock'; fa = 'موجود در انبار';
					|it = 'In disposizione';
					|pl = 'Dostępny towar';
					|tr = 'Stokta'"));
	Array.Add(NStr("vi = 'Dịch vụ được sử dụng';
					|ru = 'Услуга доступна';
					|en = 'The service is available'; fa = 'The service is available';
					|it = 'Servizio accessibile';
					|pl = 'Usługa jest dostępna';
					|tr = 'Hizmet erişilebilir'"));
	Array.Add(NStr("vi = 'Cần làm chính xác';
					|ru = 'Требует уточнения';
					|en = 'Requires clarification'; fa = 'نیاز به شفاف‌سازی دارد';
					|it = 'Richiede chiarimenti';
					|pl = 'Wymaga uściślenia';
					|tr = 'Netleştirme gerekiyor'"));
	Array.Add(NStr("vi = 'Đang chờ';
					|ru = 'Ожидается';
					|en = 'Expected'; fa = 'مورد انتظار';
					|it = 'Previsto';
					|pl = 'Oczekiwane';
					|tr = 'Beklenen'") + " ");
	Array.Add(NStr("vi = 'Theo biên';
					|ru = 'Согласно графика';
					|en = 'According to the schedule'; fa = 'According to the schedule';
					|it = 'In conformità del grafico';
					|pl = 'Zgodnie z harmonogramem';
					|tr = 'Programa göre'"));
	Array.Add(NStr("vi = 'Được phép theo đơn hàng';
					|ru = 'Доступно под заказ';
					|en = 'Available to order'; fa = 'Available to order';
					|it = 'Disponibile su richiesta';
					|pl = 'Dostępne do zamówienia';
					|tr = 'Sipariş üzerine mevcut'"));
	Array.Add(NStr("vi = 'Không có';
					|ru = 'Нет в наличии';
					|en = 'Not available'; fa = 'در دسترس نیست';
					|it = 'Non è disponibile';
					|pl = 'Brak';
					|tr = 'Stokta yok'"));
	
	Return Array;
	
EndFunction

// Generates a text representation of the occurrence of the VAT amount in the price
//
// Parameters:
//  PriceIncludesVAT  - Boolean - indicates whether the VAT amount is included in the price.
//
// Returns:
//   String - generated text representation.
//
Function TextPriceIncludesVAT(PriceIncludesVAT) Export
	
	If ValueIsFilled(PriceIncludesVAT) Then
		If PriceIncludesVAT Then
			Return NStr("vi = 'Giá gồm thuế GTGT';
						|ru = 'Цена включает НДС';
						|en = 'Price includes VAT'; fa = 'قیمت شامل مالیات بر ارزش افزوده است';
						|it = 'Il prezzo include l''IVA';
						|pl = 'Cena zawiera VAT';
						|tr = 'Fiyata KDV dahildir'");
		Else
			Return NStr("vi = 'Đơn giá không gồm thuế GTGT';
						|ru = 'Цена не включает НДС';
						|en = 'Price excludes VAT'; fa = 'Price excludes VAT';
						|it = 'Il prezzo non include l''IVA';
						|pl = 'Cena nie zawiera VAT';
						|tr = 'KDV hariç fiyat'");
		EndIf;
	Else
		Return "";
	EndIf;
	
EndFunction

Function TextCurrencyIncludesVAT(Currency, PriceIncludesVAT)
	
	TextPriceIncludesVAT = TextPriceIncludesVAT(PriceIncludesVAT);
	If Not IsBlankString(TextPriceIncludesVAT) Then
		TextPriceIncludesVAT = ", " + TextPriceIncludesVAT; 
	EndIf;
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tiền tệ: %1 %2';
																		|ru = 'Валюта: %1 %2';
																		|en = 'Currency: %1 %2'; fa = 'Currency: %1 %2';
																		|it = 'Valuta: %1 %2';
																		|pl = 'Waluta: %1 %2';
																		|tr = 'Para birimi: %1 %2'"), Currency, TextPriceIncludesVAT);
	
EndFunction

Function TextOperation(Operation)

	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Giao dịch: %1';
																		|ru = 'Операция: %1';
																		|en = 'Operation: %1'; fa = 'Operation: %1';
																		|it = 'Operazione: %1';
																		|pl = 'Operacja: %1';
																		|tr = 'İşlem: %1'"), Operation);

EndFunction

Function TextVATTaxation(VATTaxation)

	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thuế GTGT: %1';
																		|ru = 'Налогообложение НДС: %1';
																		|en = 'VAT taxation: %1'; fa = 'VAT taxation: %1';
																		|it = 'Tassazione IVA: %1';
																		|pl = 'Opodatkowanie VAT: %1';
																		|tr = 'KDV vergilendirilmesi: %1'"), VATTaxation);

EndFunction

// Generates a text representation of the form fields
//
// Parameters:
//  Form  - ClientApplicationForm - the form for which text representations are generated.
//
Procedure GenerateTextPresentationsOfDocumentFormFields(Form) Export
	
	Object = Form.Object; // DocumentObject
	
	If Not ValueIsFilled(Object.Terms) Then
		Form.TaxationText        = "";
		Form.TextCurrencyIncludesVAT  = "";
		If Not TypeOf(Object.Ref) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			Form.TextOperation               = "";
		EndIf;
	Else
		Form.TaxationText        = TextVATTaxation(Object.VATTaxation);
		Form.TextCurrencyIncludesVAT  = TextCurrencyIncludesVAT(Object.Currency, Object.PriceIncludesVAT);
		If Not TypeOf(Object.Ref) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			Form.TextOperation               = TextOperation(Object.BusinessOperation);
		EndIf;
	EndIf;
	
EndProcedure

// Performs General actions for self-service forms when they are created on the server
//
// Parameters:
//  Form  - ClientApplicationForm - the form for which the necessary actions are performed
//  Cancel  - Boolean - set to FALSE if the conditions for opening the form are not met.
//
Procedure SelfServiceFormsWhenCreatedOnServer(Form, Cancel) Export
	
	Object = Form.Object; // DocumentObject, CatalogObject
	
	AuthorizationObjectData = PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser();
	FillPropertyValues(Object, AuthorizationObjectData);
	
	If Object.Partner.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	If TypeOf(Object.Ref) = Type ("CatalogRef.Complaints") 
		And Not AuthorizationObjectData.PartnerAuthorized 
		And ValueIsFilled(AuthorizationObjectData.ContactPerson) Then
		
		If Object.PartnersAndContactPersons.FindRows(New Structure("ContactPerson", AuthorizationObjectData.ContactPerson)).Count() = 0 Then
			
			NewRow = Object.PartnersAndContactPersons.Add();
			NewRow.Partner = Object.Partner;
			NewRow.ContactPerson = AuthorizationObjectData.ContactPerson;
			
		EndIf;
		
	EndIf;
	
	If TypeOf(Object.Ref) = Type("DocumentRef.ConsignmentReportFromCustomer") 
		Or TypeOf(Object.Ref) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
		Or TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		PropsNameResponsible = "Manager";
	Else
		PropsNameResponsible = "EmployeeResponsible";
	EndIf;
	
	If Object[PropsNameResponsible] = Catalogs.Users.EmptyRef() Then
		Object[PropsNameResponsible] = SelfServiceServer.MainManagerOfPartner(Object.Partner);
	EndIf;
	
EndProcedure

Function YouCanViewBalancesInSelection() Export

	Return AccessRight("View", Metadata.InformationRegisters.InventoryAllocation);

EndFunction

Procedure FillInContactPersonSelectionList(List, Partner, ContactPerson) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	ContactPersonsForPartners.Ref,
	|	CASE
	|		WHEN ContactPersonsForPartners.Ref = &ContactPerson
	|			THEN &MyDocuments
	|		ELSE ContactPersonsForPartners.Presentation
	|	END AS Presentation,
	|	CASE
	|		WHEN ContactPersonsForPartners.Ref = &ContactPerson
	|			THEN 1
	|		ELSE 0
	|	END AS OrderingValue
	|FROM
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|WHERE
	|	ContactPersonsForPartners.Owner = &Partner
	|	AND NOT ContactPersonsForPartners.DeletionMark
	|
	|ORDER BY
	|	OrderingValue DESC";
	
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("ContactPerson", ContactPerson);
	Query.SetParameter("MyDocuments", "<" + NStr("vi = 'Văn bản của tôi';
												|ru = 'Мои документы';
												|en = 'My documents'; fa = 'My documents';
												|it = 'I miei documenti';
												|pl = 'Moje dokumenty';
												|tr = 'Belgelerim'") + ">");
	
	List.Clear();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		List.Add(Selection.Ref, Selection.Presentation);
		
	EndDo;
	
	
EndProcedure

Procedure SetBackgroundColorOfHTML5Information(HTMLText) Export
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		HTMLText = StrReplace(HTMLText, "body bgcolor=""#ffffff""", "BODY bgColor=""#fcfaeb""");
	EndIf;
	
EndProcedure



// Event handler for creating list forms
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// 	Cancel - Boolean - 
// 	StandardProcessing - Boolean -
//
Procedure ListFormOnCreateAtServer(Form, Cancel, StandardProcessing) Export

	TMCommonUseClientServer.SetFormItemProperty(
	          Form.Items,
	          "RelatedDocuments",
	          "Visible",
	          AccessRight("View", Metadata.CommonForms.RelatedDocuments));

EndProcedure

#Region Agreement

// Visibility is configured, the selection list is filled in, and the default value 
//    of the "Contract" form details is set.
//
// Parameters:
//  Data                            - Structure - parameters based on which settings are made
//  Item                           - FormField - for which settings are being made
//  CounterpartyAgreementsAreUsed  - Boolean - indicates that the configuration uses contracts.
//  ContractBusinessTransaction     - EnumRef.BusinessTransactions - business operations of the document
//
Procedure ManagingContractFormElement(Data, Item, CounterpartyAgreementsAreUsed, ContractBusinessTransaction = Undefined) Export
	
	If CounterpartyAgreementsAreUsed Then
		
		If ContractBusinessTransaction = Undefined Then
			If TypeOf(Data) = Type("ClientApplicationForm") Then
				BusinessOperation = Data.BusinessOperation;
			Else
				BusinessOperation = ?(Data.Property("BusinessOperation"),
				Data.BusinessOperation,
				Enums.BusinessTransactions.TransferToCommissionAgent);
			EndIf;
		Else
			BusinessOperation =  ContractBusinessTransaction;
		EndIf;
		
		Item.Visible = True;
		Item.Enabled = True;
		If ValueIsFilled(Data.Counterparty) Then
			FillInContractSelectionList(Data, Item.ChoiceList, BusinessOperation);
			If Not ValueIsFilled(Data.Contract) Then
				FillInDefaultContract(Data, BusinessOperation) ;
			EndIf;
		Else
			Data.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	Else
		Data.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		Item.Visible = False;
	EndIf;
	
EndProcedure

Procedure FillInDefaultContract(Data, BusinessOperation)
	
	Data.Contract = SalesServer.GetDefaultContract(
		Data,
		BusinessOperation,
		Data.Currency);
	
EndProcedure

Procedure FillInContractSelectionList(Data, ChoiceList, BusinessOperation) 
	
	ChoiceList.LoadValues(
	SalesServer.GetAvailableContracts(
		Data.Contract,
		Data.Partner,
		Data.Counterparty,
		Data.Organization,
		BusinessOperation,
		Data.Currency,
		Data.Terms));
	
EndProcedure

#EndRegion

#Region Counterparties

// visibility is configured, the selection list is filled in, and the default value 
//    of the Attribute of the "counterparty" form is set.
//
// Parameters:
//  Object                 - DocumentObject, ClientApplicationForm - an object containing the Counterparty and Partner Attributes.
//  Data                 - Structure - parameters on the basis of which the settings are performed.
//  Item                - FormField - for which settings are being made.
//  FillingInByAgreement - Boolean - indicates that you need to fill in the agreement
//
Procedure ManagingCounterpartyFormElement(Object, Data, Item, FillingInByAgreement = False) Export

	If Item.ChoiceList.Count() = 0 Then
		FillInCounterpartySelectionList(Data.Partner, Item);
	EndIf;
	
	If ValueIsFilled(Data.Counterparty) Then
		Item.Enabled = False;
		Object.Counterparty = Data.Counterparty;
		FillingInByAgreement = True;
	Else
		Item.Enabled = True;
		If Not ValueIsFilled(Object.Counterparty) Then
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
		EndIf;
		FillingInByAgreement = False;
	EndIf;

EndProcedure

// Fills in the counterparty selection list
//
// Parameters:
//  Partner  - CatalogRef.Partners - the partner on the basis of which the selection list is generated
//  List of selections - List of values - generated selection list.
//
Procedure FillInCounterpartySelectionList(Partner, Item)

	Item.ChoiceList.LoadValues(PartnersAndCounterparties.GetAllPartnersOfPartner(Partner));

EndProcedure

#EndRegion

#Region Warehouses

// Visibility is configured, the selection list is filled in, and the default value 
//    of the "Warehouse" form details is set.
//
// Parameters:
//  Object  - DocumentObject, ClientApplicationForm - object containing the Warehouse details
//  Data  - Structure - parameters based on which settings are made
//  Item - FormField - for which settings are being made.
//
Procedure ManagingWarehouseFormElement(Object, Data, Item) Export

	If Data = Undefined Then
		Item.Enabled = False;
		Return;
	EndIf;
	
	DonTGetWarehouseGroups = Not GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments");    
	DonTReceiveWarehouseGroupsForOrdersOnly = (TypeOf(Object) <> Type("ClientApplicationForm") 
												And TypeOf(Object.Ref) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	
	FillInWarehouseSelectionList(Data, Item, DonTGetWarehouseGroups, DonTReceiveWarehouseGroupsForOrdersOnly);
	
	If ValueIsFilled(Data.Warehouse) Then
		
		If Not (DonTGetWarehouseGroups And Data.ThisIsWarehouseGroup) Then
			Object.Warehouse = Data.Warehouse;
		EndIf;
		
		If Data.ThisIsWarehouseGroup Then
			Item.Enabled = True;
			
		Else
			Item.Enabled = False;
		EndIf;
		
	Else
		Item.Enabled = True;
	EndIf;

EndProcedure

// Fills in the counterparty selection list
//
// Parameters:
//  Data  - Structure, QueryResultSelection - parameters required to determine the warehouses available to the partner.
//  Item - FormField - for which settings are being made.
//  DonTGetWarehouseGroups - Boolean - do not receive warehouse groups that cannot be selected in the Attributes.
//  DonTReceiveWarehouseGroupsForOrdersOnly - Boolean - Do not receive groups of warehouses that have a selected group installed only in orders.
//
Procedure FillInWarehouseSelectionList(Data, Item, DonTGetWarehouseGroups, DonTReceiveWarehouseGroupsForOrdersOnly = False) Export
	
	Item.ChoiceList.LoadValues(AllAvailablePartnerWarehouses(
								Data, DonTGetWarehouseGroups, DonTReceiveWarehouseGroupsForOrdersOnly));
	
EndProcedure

// Generates an array of warehouses available to the partner
//
// Parameters:
//  Data  - Structure, QueryResultSelection - parameters required to determine the warehouses available to the partner.
//  DonTGetWarehouseGroups - Boolean - do not receive warehouse groups that cannot be selected in the Attributes.
//  DonTReceiveWarehouseGroupsForOrdersOnly - Boolean - Do not receive groups of warehouses that have a selected group installed only in orders.
//
// Returns:
//   Array of CatalogRef.Warehouses  - an array containing the warehouses available for selection.
//
Function AllAvailablePartnerWarehouses(Data, DonTGetWarehouseGroups, DonTReceiveWarehouseGroupsForOrdersOnly)
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	Warehouses.Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	NOT Warehouses.DeletionMark";
	
	If Data.ThisIsWarehouseGroup Then
		Query.Text = Query.Text + "
		            |	AND Warehouses.Ref IN HIERARCHY(&Warehouse)";
		Query.SetParameter("Warehouse", Data.Warehouse );
	EndIf;
	
	If DonTGetWarehouseGroups Then
		Query.Text = Query.Text + "
		            |	AND NOT Warehouses.IsFolder";
	Else
		If DonTReceiveWarehouseGroupsForOrdersOnly Then
			Query.Text = Query.Text + "
		    	        |	AND CASE WHEN Warehouses.IsFolder THEN NOT Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders) ELSE TRUE END";
		EndIf;
		
		Query.Text = Query.Text + "
		            |	AND CASE WHEN Warehouses.IsFolder THEN NOT Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.Disable) ELSE TRUE END";
	EndIf;
	
	Query.Text = Query.Text + "
	|ORDER BY
	|	Warehouses.Description";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return New Array;
	EndIf;
	
	Return Result.Unload().UnloadColumn("Ref");
	
EndFunction

// Visibility is configured, the selection list is filled in, and the default value 
//    of the "Warehouse" form details is set.
//
// Parameters:
//  Object  - DocumentObject, ClientApplicationForm - object containing the Attributes of the payment form
//  Data  - Structure                                  - parameters based on which settings are made
//  Item - FormField                                  - for which settings are being made.
//
Procedure ManagingFormElementPaymentForm(Object, Data, Item) Export
	
	If ValueIsFilled(Data.PaymentMethod) Then
		Object.PaymentMethod = Data.PaymentMethod;
		Item.ReadOnly = True;
	Else
		If Not ValueIsFilled(Object.PaymentMethod) Then
			Object.PaymentMethod = Item.ChoiceList[0].Value;
		EndIf;
		Item.ReadOnly = False;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
