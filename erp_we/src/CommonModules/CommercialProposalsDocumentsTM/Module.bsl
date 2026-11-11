////////////////////////////////////////////////////////////////////////////////
// Subsystem "Objects UT11, KA2, UP2".
// General module.Commercial proposals and documents.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region InitializingDocuments

// See CommercialProposalsDocumentsOverridable.ProcessingDocumentFilling.
//
Procedure ProcessingDocumentFilling(Object, FillingData, FillingText, StandardProcessing) Export

	If Not Object.IsNew() Then
		Return;
	EndIf;
	
	If TypeOf(Object) = Type("DocumentObject.CommercialProposalForCustomer") Then
		
		CommercialOfferToClientFillingProcessing(Object, FillingData, FillingText, StandardProcessing);
		ResponsiblePersonsServer.FillInManager_(Object, False, "Client.MainManager");

	
	EndIf;
	
	CommercialProposalsDocumentsLocalization.ProcessingDocumentFilling(Object, FillingData, FillingText, StandardProcessing);
	
	If Not ValueIsFilled(Object.Manager) Then
		Object.Manager = Users.CurrentUser();
	EndIf;

	If Not ValueIsFilled(Object.Author) Then
		Object.Author = Users.CurrentUser();
	EndIf;
	
	AttributesDetails1 = New Structure;
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	If TypeOf(Object) = Type("DocumentObject.CommercialProposalForCustomer") Then
		Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Client";
	
				
	EndIf;
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	ObjectsFillingByStatistics.FillObjectAttributes(Object, FillingData, AttributesDetails1);

	Object.Organization  = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	
	If TypeOf(Object) = Type("DocumentObject.CommercialProposalForCustomer") Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
		StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		StructureOfFillingInVATRate.InitializingIncomingDocument = True;
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			CachedValues.ProcessedRows,
			StructureOfActions,
			Object.Goods,
			CachedValues);
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenFillingInListOfCurOfBusinessCommercialOffers
//
// Parameters:
//  ToDoList - See CommercialProposalsDocumentsOverridable.WhenFillingInListOfCurOfBusinessCommercialOffers.ToDoList
//  DocumentName - See CommercialProposalsDocumentsOverridable.WhenFillingInListOfCurOfBusinessCommercialOffers.DocumentName
//
Procedure WhenFillingInListOfCurOfBusinessCommercialOffers(ToDoList, DocumentName) Export
	
	If DocumentName = "CommercialProposalForCustomer"
		And Common.SubsystemExists(
		"ElectronicInteraction.CommercialProposals.CommercialProposalsDocuments.CommercialProposalForCustomer") Then
		
		CommonQueryParameters = ToDoListServer.CommonQueryParameters();
		FormName = "Document.CommercialProposalForCustomer.Form.ListForm";
		
		Enabled =
			AccessRight("Edit", Metadata.Documents.CommercialProposalForCustomer)
			And AccessRight("Read"      , Metadata.InformationRegisters.StatesOfCommercialProposalsToCustomers)
			And GetFunctionalOption("UseCommercialProposalsForCustomers");
			
		If Enabled Then
			
			Query = New Query;
			Query.Text = "
			|SELECT ALLOWED
			|	COUNT(DISTINCT CASE
			|			WHEN StatesOfCommercialProposalsToCustomers.State = VALUE(Enum.StatesOfCommercialProposalsToCustomers.PendingApproval)
			|				THEN StatesOfCommercialProposalsToCustomers.CommercialProposalForCustomer
			|		END) AS CommercialProposalsUnderApproval,
			|	COUNT(DISTINCT CASE
			|			WHEN StatesOfCommercialProposalsToCustomers.State = VALUE(Enum.StatesOfCommercialProposalsToCustomers.Prepared_)
			|				THEN StatesOfCommercialProposalsToCustomers.CommercialProposalForCustomer
			|		END) AS CommercialProposalsAreBeingPrepared,
			|	COUNT(DISTINCT CASE
			|			WHEN StatesOfCommercialProposalsToCustomers.State = VALUE(Enum.StatesOfCommercialProposalsToCustomers.Valid)
			|					AND &UpdateDate <= StatesOfCommercialProposalsToCustomers.CommercialProposalForCustomer.ValidityPeriod
			|				THEN StatesOfCommercialProposalsToCustomers.CommercialProposalForCustomer
			|		END) AS CommercialOffersAreValid
			|FROM
			|	Document.CommercialProposalForCustomer AS DocumentCommercialProposalForCustomer
			|		LEFT JOIN InformationRegister.StatesOfCommercialProposalsToCustomers AS StatesOfCommercialProposalsToCustomers
			|		ON (StatesOfCommercialProposalsToCustomers.CommercialProposalForCustomer = DocumentCommercialProposalForCustomer.Ref)
			|WHERE
			|	DocumentCommercialProposalForCustomer.Manager = &User
			|	AND DocumentCommercialProposalForCustomer.Posted
			|	AND StatesOfCommercialProposalsToCustomers.State <> VALUE(Enum.StatesOfCommercialProposalsToCustomers.Canceled)";
			
			Result = ToDoListServer.NumericUserTasksIndicators(Query, CommonQueryParameters);
			
			// Filling out cases.
			// Commercial offers to clients
			UserTaskParent = ToDoList.Add();
			UserTaskParent.Id  = "CommercialProposalsForCustomers";
			UserTaskParent.Presentation  = NStr("vi = 'Báo giá cho khách hàng';
												|ru = 'Коммерческие предложения клиентам';
												|en = 'Sales quotations'; fa = 'پیشنهادهای فروش';
												|it = 'Offerte commerciali ai clienti';
												|pl = 'Oferty komercyjne do klientów';
												|tr = 'Müşterilere sunulan satış teklifleri'");
			UserTaskParent.Owner       = Metadata.Subsystems.Sales;
			
			// CommercialOffersToClientsOnApproval
			StatesList = New ValueList;
			StatesList.Add(Enums.StatesOfCommercialProposalsToCustomers.PendingApproval);
			
			FilterParameters = New Structure;
			FilterParameters.Insert("StateFilter",   StatesList);
			FilterParameters.Insert("Relevance",     "");
			FilterParameters.Insert("UpdateDate", CommonQueryParameters.DateEmpty);
			FilterParameters.Insert("Manager",         CommonQueryParameters.User);
			
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = "CommercialOffersToClientsOnApproval";
			ToDoItem.HasToDoItems       = Result.CommercialProposalsUnderApproval > 0;
			ToDoItem.Presentation  = NStr("vi = 'Cần thống nhất';
											|ru = 'На согласовании';
											|en = 'Pending approval'; fa = 'در انتظار تأیید';
											|it = 'In fase di definizione';
											|pl = 'Na uzgodnieniu';
											|tr = 'Onay bekliyor'");
			ToDoItem.Count     = Result.CommercialProposalsUnderApproval;
			ToDoItem.Important         = False;
			ToDoItem.Form          = FormName;
			ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
			ToDoItem.Owner       = "CommercialProposalsForCustomers";
			
			// Commercial offerenclientsreferences
			StatesList = New ValueList;
			StatesList.Add(Enums.StatesOfCommercialProposalsToCustomers.Prepared_);
			
			FilterParameters = New Structure;
			FilterParameters.Insert("StateFilter",   StatesList);
			FilterParameters.Insert("Relevance",     "");
			FilterParameters.Insert("UpdateDate", CommonQueryParameters.DateEmpty);
			FilterParameters.Insert("Manager",         CommonQueryParameters.User);
			
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = "CommercialProposalsAreBeingPrepared";
			ToDoItem.HasToDoItems       = Result.CommercialProposalsAreBeingPrepared > 0;
			ToDoItem.Presentation  = NStr("vi = 'Đang chuẩn bị';
											|ru = 'Подготавливается';
											|en = 'Draft'; fa = 'پیش‌نویس';
											|it = 'In preparazione';
											|pl = 'Draft';
											|tr = 'Hazırlanıyor'");
			ToDoItem.Count     = Result.CommercialProposalsAreBeingPrepared;
			ToDoItem.Important         = False;
			ToDoItem.Form          = FormName;
			ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
			ToDoItem.Owner       = "CommercialProposalsForCustomers";
			
			// CommercialOffersToCustomersAreValid
			StatesList = New ValueList;
			StatesList.Add(Enums.StatesOfCommercialProposalsToCustomers.Valid);
			
			FilterParameters = New Structure;
			FilterParameters.Insert("StateFilter",   StatesList);
			FilterParameters.Insert("Relevance",     NStr("vi = 'Chưa hết hạn';
															|ru = 'Не истек';
															|en = 'Not expired'; fa = 'Not expired';
															|it = 'Non scaduto';
															|pl = 'Nie wygasnął';
															|tr = 'Süresi dolan'"));
			FilterParameters.Insert("UpdateDate", CommonQueryParameters.DateEmpty);
			FilterParameters.Insert("Manager",         CommonQueryParameters.User);
			
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = "CommercialOffersToCustomersAreValid";
			ToDoItem.HasToDoItems       = Result.CommercialOffersAreValid > 0;
			ToDoItem.Presentation  = NStr("vi = 'Có hiệu lực';
											|ru = 'Действует';
											|en = 'Valid'; fa = 'معتبر';
											|it = 'In vigore';
											|pl = 'Valid';
											|tr = 'Aktif'");
			ToDoItem.Count     = Result.CommercialOffersAreValid;
			ToDoItem.Important         = False;
			ToDoItem.Form          = FormName;
			ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
			ToDoItem.Owner       = "CommercialProposalsForCustomers";
			
			If Result.CommercialProposalsUnderApproval > 0
				Or Result.CommercialProposalsAreBeingPrepared > 0
				Or Result.CommercialOffersAreValid > 0 Then
				UserTaskParent.HasToDoItems = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	CommercialProposalsDocumentsLocalization.WhenFillingInListOfCurOfBusinessCommercialOffers(ToDoList, DocumentName);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.InitializingFormCommands.
//
Procedure InitializingFormCommands(EventName, ObjectName, Context, Result = Undefined, Parameters = Undefined) Export
	
	If EventName = "AddGenerationCommands" Then
		AddGenerationCommands(ObjectName, Context, Parameters);
	ElsIf EventName = "AddGenerateCommand" Then
		Result = AddGenerateCommand(ObjectName, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region ObtainingInformationBaseData

// Parameters for filling in the terms of purchase for commercial offers.
// 
// Returns:
//  Structure - Parameters For Filling In The Terms Of Purchase For Commercial Offers:
// * Document - DocumentRef.PurchaseRequest, DocumentRef.ApplicationForCollateral - The document is the basis for requesting commercial proposals.
// * DateOfCourse - Date - For which the exchange rates will be used when converting prices into the currency of the document being filled in.
// * Currency - CatalogRef.Currencies - In which the received prices will be recalculated to fill out the document.
// * PriceIncludesVAT - Undefined, Boolean - When specifying the value of the flag from the source document, if necessary, recalculates the price in accordance with this flag.
// * ThereIsAPartner - Boolean - Flag that indicates the presence of the "Partner" column in the table being filled in.
// * ThereIsCounterparty - Boolean - Flag that determines the presence of the "Counterparty" column in the table being filled in.
// * ThereIsItemLine - Boolean - Flag that specifies the presence of the "Nomenclature by row" column in the table to be filled in.
// * LineNumbers - Array of Number - The row numbers of the table to be filled in, in which prices need to be filled in.
// * ActionsWithModifiedStrings - Structure - Description of batch processing actions that will be performed with the modified lines:
// ** RecalculateNumberOfPackages - Undefined - The action is to convert the quantity into the number of packages, because the distribution of prices is performed by storage units.
Function ParametersForFillingInTermsOfPurchaseForCommercialOffers() Export 
	
	ReturnValue = New Structure;
	
	ReturnValue.Insert("Document", Documents.PurchaseRequest.EmptyRef());
	ReturnValue.Insert("DateOfCourse", CurrentSessionDate());
	ReturnValue.Insert("Currency", Catalogs.Currencies.EmptyRef());
	ReturnValue.Insert("PriceIncludesVAT", Undefined);
	
	ReturnValue.Insert("ThereIsAPartner", False);
	ReturnValue.Insert("ThereIsCounterparty", False);
	ReturnValue.Insert("ThereIsItemLine", False);
	ReturnValue.Insert("LineNumbers", New Array);
	
	ReturnValue.Insert("ActionsWithModifiedStrings", New Structure("RecalculateNumberOfPackages"));
	
	Return ReturnValue;
	
EndFunction

// Returns the flag for using the functionality of requests for commercial offers.
// 
// Returns:
//  Boolean
Function UseRequestsForCommercialOffersFromSuppliers() Export
	Return CommercialProposalsDocumentsLocalization.UseRequestsForCommercialOffersFromSuppliers();
EndFunction

// Fills in the purchase conditions in the table for commercial offers:
// 
// Parameters:
//  Goods - ValueTable, FormDataCollection - In which you need to fill in the prices and their source (partner, counterparty, VAT rate).
//  FillParameters - See CommercialProposalsDocumentsTM.ParametersForFillingInTermsOfPurchaseForCommercialOffers
// 
// Returns:
//  Structure:
// * Cancel - Boolean - If it is cocked, then the prices cannot be filled in, the reason for the error is indicated in the "Text errors".
// * ErrorText - String - Filled in if the "Failure" flag is set. Information about the reason why prices cannot be filled in.
// * LinesWithBlankPurchaseConditions - Array of ValueTableRow, FormDataCollectionItem - lines for which there are no purchase conditions.
// * ModifiedRows - Array of ValueTableRow, FormDataCollectionItem - Changed (and added) rows of the table part.
Function FillInTermsOfPurchaseBasedOnCommercialOffers(Goods, FillParameters) Export
	
	Return CommercialProposalsDocumentsLocalization.FillInTermsOfPurchaseBasedOnCommercialOffers(Goods, FillParameters);
		
EndFunction

// See CommercialProposalsDocumentsOverridable.AnalyzedSourcesOfProposals.
//
// Parameters:
//  Sources - ValueTable:
//
Procedure AnalyzedSourcesOfProposals(Sources) Export
	
	TermsOfPurchaseFromVendors = Metadata.Catalogs.TermsOfPurchaseFromVendors;
	
	NewRow = Sources.Add();
	NewRow.SourceName           = TermsOfPurchaseFromVendors.Name;
	NewRow.SourcePresentation = TermsOfPurchaseFromVendors.Synonym;
	NewRow.BriefPresentation   =  NStr("vi = 'Điều kiện mua hàng';
										|ru = 'Условия закупок';
										|en = 'Purchase conditions'; fa = 'شرایط خرید';
										|it = 'Condizioni di acquisto';
										|pl = 'Warunki zakupów';
										|tr = 'Satın alma koşulları'");
	NewRow.SourceImage      = PictureLib.SetTermsOfPurchasesStatusToValid;
	NewRow.Use           = True;
	NewRow.Use           = True;
	NewRow.SupportsSaving = False;
	
	ItemsPricesOfVendor = Metadata.InformationRegisters.ItemsPricesOfVendor;
	
	NewRow = Sources.Add();
	NewRow.SourceName           = ItemsPricesOfVendor.Name;
	NewRow.SourcePresentation = ItemsPricesOfVendor.Synonym;
	NewRow.BriefPresentation   = NStr("vi = 'Đơn giá nhà cung cấp';
										|ru = 'Цены поставщиков';
										|en = 'Vendor prices'; fa = 'قیمت‌های تأمین‌کننده';
										|it = 'Prezzi dei fornitori';
										|pl = 'Cenniki dostawców';
										|tr = 'Tedarikçi fiyatları'");
	NewRow.SourceImage      = PictureLib.ImportValidPrices;
	NewRow.Use           = True;
	NewRow.SupportsSaving = False;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInProductData.
//
Procedure FillInProductData(Val ItemList, FieldValues) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	Products.Ref AS ProductsLink,
		|	Products.DescriptionFull AS NomenclatureName
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.Ref IN(&ItemList)";
	
	Query.SetParameter("ItemList", ItemList);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		FillPropertyValues(
			FieldValues[SelectionDetailRecords.ProductsLink],
			SelectionDetailRecords);
	EndDo;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInProductCharacteristicsData.
//
Procedure FillInProductCharacteristicsData(Val Characteristics, FieldValues) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	ItemsCharacteristics.Ref AS CharacteristicReference,
		|	ItemsCharacteristics.DescriptionFull AS CharacteristicName
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.Ref IN(&ListOfCharacteristics)";
	
	Query.SetParameter("ListOfCharacteristics", Characteristics);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		FillPropertyValues(
			FieldValues[SelectionDetailRecords.CharacteristicReference],
			SelectionDetailRecords);
	EndDo;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInUnitData.
//
Procedure FillInUnitData(Val UnitsOfMeasurement, FieldValues) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	UnitsOfMeasurement.Description AS LogisticsPackagingName,
		|	CASE
		|		WHEN UnitsOfMeasurement.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|			THEN UnitsOfMeasurement.UnitOfMeasure.Description
		|		ELSE UnitsOfMeasurement.Description
		|	END AS UnitOfMeasurementName,
		|	CASE
		|		WHEN UnitsOfMeasurement.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|			THEN UnitsOfMeasurement.UnitOfMeasure.Code
		|		ELSE UnitsOfMeasurement.Code
		|	END AS UnitOfMeasurementCodeOceania,
		|	UnitsOfMeasurement.Ref AS UnitOfMeasureLink,
		|	CASE
		|		WHEN ISNULL(UnitsOfMeasurement.Numerator, 0) = 0
		|			THEN 1
		|		ELSE UnitsOfMeasurement.Numerator
		|	END AS Numerator,
		|	CASE
		|		WHEN ISNULL(UnitsOfMeasurement.Denominator, 0) = 0
		|			THEN 1
		|		ELSE UnitsOfMeasurement.Denominator
		|	END AS Denominator
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS UnitsOfMeasurement
		|WHERE
		|	UnitsOfMeasurement.Ref IN(&UnitsOfMeasurement)";
	
	Query.SetParameter("UnitsOfMeasurement", UnitsOfMeasurement);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		FillPropertyValues(
			FieldValues[SelectionDetailRecords.UnitOfMeasureLink],
			SelectionDetailRecords);
	EndDo;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenDefiningDefaultUnitOfMeasurement.
//
Procedure WhenDefiningDefaultUnitOfMeasurement(UnitOfMeasure) Export

	UnitCode = "796";
	UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.FindByCode(UnitCode);

EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInDataOfProductBarcodes.
//
Procedure FillInDataOfProductBarcodes(ItemList) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	ItemsBarcodes.Products AS Products,
		|	ItemsBarcodes.Characteristic AS Characteristic,
		|	ItemsBarcodes.UnitOfMeasure AS UnitOfMeasure
		|INTO Goods
		|FROM
		|	&ItemList AS ItemsBarcodes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.UnitOfMeasure AS UnitOfMeasure,
		|	Barcodes.Barcode AS Barcode
		|FROM
		|	Goods AS Goods
		|		INNER JOIN InformationRegister.ItemsBarcodes AS Barcodes
		|		ON Goods.Products = Barcodes.Products
		|			AND Goods.Characteristic = Barcodes.Characteristic
		|			AND Goods.UnitOfMeasure = Barcodes.Package";
	
	Query.SetParameter("ItemList", ItemList);
	
	QueryResult = Query.Execute();
	
	ItemList = QueryResult.Unload();
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.DataOfParticipantOfCommercialOffers.
//
Procedure DataOfParticipantOfCommercialOffers(Val Member, ParticipantData) Export
	
	CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(Member, CurrentSessionDate());
	
	ParticipantData = New Structure;
	ParticipantData.Insert("Ref", Member);
	ParticipantData.Insert("Description", CompanyInformation.NameAbbreviated);
	ParticipantData.Insert("Kind", New Structure);
	
	If CompanyInformation.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur Then
		
		IndividualEntrepreneur = New Structure("TIN, Name, LastName, MiddleName");
		FillPropertyValues(IndividualEntrepreneur, CompanyInformation);
		
		CommercialProposalsDocumentsLocalization.FillInPartsOfEntrepreneurSName(
			CompanyInformation.OfficialName, IndividualEntrepreneur);
		
		ParticipantData.Kind.Insert("IndividualEntrepreneur", IndividualEntrepreneur);
		
	ElsIf CompanyInformation.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity Then
		
		BusinessEntity = New Structure("TIN, CRTR");
		FillPropertyValues(BusinessEntity, CompanyInformation);
		
		ParticipantData.Kind.Insert("BusinessEntity", BusinessEntity);
		
	EndIf;
	
	LegalAddress = New Structure("Presentation, Code");
	LegalAddress.Presentation = CompanyInformation.LegalAddress;
	
	ParticipantData.Insert("LegalAddress", LegalAddress);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInWarehouseAddress.
//
Procedure FillInWarehouseAddress(Val Warehouse, DeliveryAddress) Export
	
	ContactInformationTable1 = ContactsManager.ObjectContactInformation(Warehouse,
		Catalogs.ContactInformationKinds.WarehouseAddress, CurrentSessionDate(), False);
		
	If ValueIsFilled(ContactInformationTable1) Then
		
		DeliveryAddress.Presentation = ContactInformationTable1[0].Presentation;
		CommercialProposalsDocumentsLocalization.FillInAddressInformation(ContactInformationTable1[0].FieldValues, DeliveryAddress);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.GetCounterpartyPartner.
//
Procedure GetCounterpartyPartner(Val Counterparty, Partner) Export
	Partner = CashServer.GetCounterpartyPartner(Counterparty);
EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInContactPersonOfDocumentAccordingToElectronicDocument.
//
Procedure FillInContactPersonOfDocumentAccordingToElectronicDocument(Counterparty, ContactPersonDetails, ContactPerson) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	NestedQuery.ContactPerson AS ContactPerson,
	|	NestedQuery.OrderingValue AS OrderingValue
	|FROM
	|	(SELECT
	|		ContactPersonsForPartners.Ref AS ContactPerson,
	|		3 AS OrderingValue
	|	FROM
	|		Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|			INNER JOIN Catalog.Counterparties AS Counterparties
	|			ON ContactPersonsForPartners.Owner = Counterparties.Partner
	|	WHERE
	|		ContactPersonsForPartners.Description = &Description
	|		AND Counterparties.Ref = &Counterparty
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ContactPersonsForPartners.Ref,
	|		2
	|	FROM
	|		Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
	|			INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|			ON ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsForPartners.Ref
	|			INNER JOIN Catalog.Counterparties AS Counterparties
	|			ON ContactPersonsForPartners.Owner = Counterparties.Partner
	|	WHERE
	|		Counterparties.Ref = &Counterparty
	|		AND ContactPersonsOfPartnersContactInformation.Type = &ContactInformationTypePhone
	|		AND ContactPersonsOfPartnersContactInformation.PhoneNumber = &PhoneNumber
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ContactPersonsForPartners.Ref,
	|		1
	|	FROM
	|		Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
	|			INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|			ON ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsForPartners.Ref
	|			INNER JOIN Catalog.Counterparties AS Counterparties
	|			ON ContactPersonsForPartners.Owner = Counterparties.Partner
	|	WHERE
	|		Counterparties.Ref = &Counterparty
	|		AND ContactPersonsOfPartnersContactInformation.Type = &TypeOfContactInformationEmailAddress
	|		AND ContactPersonsOfPartnersContactInformation.EMAddress = &Email) AS NestedQuery
	|
	|ORDER BY
	|	OrderingValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Counterparties.Partner AS Partner
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Ref = &Counterparty";
	
	Query.SetParameter("Counterparty",                                   Counterparty);
	Query.SetParameter("Description",                                 ContactPersonDetails.LastFirstName);
	Query.SetParameter("ContactInformationTypePhone",               Enums.ContactInformationTypes.Phone);
	Query.SetParameter("PhoneNumber",                                ContactPersonDetails.Phone);
	Query.SetParameter("TypeOfContactInformationEmailAddress", Enums.ContactInformationTypes.Email);
	Query.SetParameter("Email",                        ContactPersonDetails.Email);
	
	Result = Query.ExecuteBatch(); 
	
	SampleFound = Result[0].Select();
	
	If SampleFound.Next() Then
		ContactPerson = SampleFound.ContactPerson;
	ElsIf AccessRight("Insert", Metadata.Catalogs.ContactPersonsForPartners) Then 
		
		CreationParameters = Catalogs.ContactPersonsForPartners.ContactPersonCreationParameters();
		CreationParameters.Description          = ContactPersonDetails.LastFirstName;
		CreationParameters.Email = ContactPersonDetails.Email;
		CreationParameters.Phone               = ContactPersonDetails.Phone;
		
		SamplePartner = Result[1].Select();
		SamplePartner.Next();
		
		CreationParameters.Partner = SamplePartner.Partner;
		
		CreationResult = Catalogs.ContactPersonsForPartners.ResultOfCreatingContactPerson(CreationParameters);
		
		If CreationResult.Errors.Count() = 0 Then
			ContactPerson = CreationResult.ContactPerson;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OffersFromSourcesOnRequestForCommercialOffers(Val ObjectReference, Val AnalyzedSources, FoundOffers) Export
	
	CommercialProposalsDocumentsLocalization.OffersFromSourcesOnRequestForCommercialOffers(ObjectReference, AnalyzedSources, FoundOffers);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.ProcessingProductSelectionResults.
//
Procedure ProcessingProductSelectionResults(Form, ValueSelected, AdditionalParameters, ProcessingResult) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientProcessingResultOfSelectionOfProducts(Form, ValueSelected, AdditionalParameters, ProcessingResult);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.LoadDataReceivedFromExternalFile.
//
Procedure LoadDataReceivedFromExternalFile(Form, ValueSelected) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientToDownloadDataReceivedFromExternalFile(Form, ValueSelected);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.ProcessBarcodeInput.
//
Procedure ProcessBarcodeInput(Form, BarcodeData_1, ProcessingResult) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientToProcessBarcodeInput(Form, BarcodeData_1, ProcessingResult);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.ProcessBarcodeInput.
//
Procedure ProcessReceivedTSDData(Form, TableOfGoods, ProcessingResult) Export
	
	CommercialOfferToClientToProcessBarcodeInput(Form, TableOfGoods, ProcessingResult);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInPricesByPriceKind.
//
Procedure FillInPricesByPriceKind(Form, PriceKind, AdditionalParameters) Export
	
	CommercialOfferToClientFillInPricesByTypeOfPrices(Form, PriceKind, AdditionalParameters);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInPricesBySalesCondition.
//
Procedure FillInPricesBySalesCondition(Form, SalesCondition, AdditionalParameters) Export
	
	CommercialOfferToClientToFillInPricesAccordingToSalesCondition(Form, SalesCondition, AdditionalParameters);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.CalculateDiscountsOnServer.
//
Procedure CalculateDiscountsOnServer(Form, ProcessingResult)  Export
	
	CommercialOfferToClientToCalculateDiscounts(Form, ProcessingResult);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.PrepareOpeningInformationAboutDiscountsOnServer.
//
Procedure PrepareOpeningInformationAboutDiscountsOnServer(Form, ProcessingResult) Export
	
	CommercialOfferToClientToPrepareOpeningOfInformationAboutDiscountsOnServer(Form, ProcessingResult);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenCancelingManualDiscountsOnServer.
//
Procedure WhenCancelingManualDiscountsOnServer(Form, ProcessingResult) Export
	
	CommercialOfferToClientWhenCancelingManualDiscountsOnServer(Form, ProcessingResult);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenAssigningManualDiscountOnServer.
//
Procedure WhenAssigningManualDiscountOnServer(Form, ProcessingResult) Export
	
	CommercialOfferToClientWhenAssigningManualDiscountOnServer(Form, ProcessingResult);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.AfterAssigningManualDiscountOnServer.
//
Procedure AfterAssigningManualDiscountOnServer(Form, SelectedRows, ProcessingResult, AdditionalParameters) Export
	
	CommercialOfferToClientAfterAssigningManualDiscountOnServer(Form, SelectedRows, ProcessingResult, AdditionalParameters);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.AfterAssigningAutomaticDiscountOnServer.
//
Procedure AfterAssigningAutomaticDiscountOnServer(Form, Result, AdditionalParameters) Export
	
	CommercialOfferToClientAfterAssigningAutomaticDiscountOnServer(Form, Result, AdditionalParameters);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.AfterAssigningManualDiscountOnServer.
//
Procedure WhenAssigningAutomaticDiscountsOnServer(Form, Result) Export
	
	CommercialOfferToClientWhenAssigningAutomaticDiscountsOnServer(Form, Result);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenExecutingOverridableCommand.
//
Procedure WhenExecutingOverridableCommand(Form, CommandName, ProcessingResult) Export
	
	CommercialOfferToClientWhenExecutingOverridableCommand(Form, CommandName, ProcessingResult);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenExecutingOverridableCommand.
//
Procedure GoodsSelectionServer(Form, FieldName, ProcessingResult) Export
	
	If FieldName <> "GoodsCommentForCustomer"
		Or FieldName <> "GoodsInternalComment" Then
			
		ProcessingResult = ParametersForOpeningSetComposition(Form);
		
	EndIf;
	
EndProcedure

Procedure OnAddReportsCommands(ObjectName, ReportsCommands, Parameters) Export
	
	If ObjectName = "Document.CommercialProposalForCustomer" Then
		
		CommercialOfferToClientWhenAddingReportCommands(ReportsCommands, Parameters);
		
	EndIf;
	
	CommercialProposalsDocumentsLocalization.OnAddReportsCommands(ObjectName, ReportsCommands, Parameters);
		
EndProcedure

// See CommercialProposalsDocumentsOverridable.SaveUserChangesInSourceDocuments
//
Procedure SaveUserChangesInSourceDocuments(Sources, Cancel) Export
	
	TableSources_ = Sources.Copy(, "Source"); // See CommercialProposalsDocumentsOverridable.SaveUserChangesInSourceDocuments.Sources
	TableSources_.GroupBy("Source");
	
	For Each TableRow In TableSources_ Do
		
		Source = TableRow.Source;
		
		If Metadata.Documents.Contains(Source.Metadata()) Then
			
			Filter = New Structure("Source", Source);
			FoundRows = Sources.FindRows(Filter);
			
			BeginTransaction();
			
			Try
				Block = New DataLock();
				LockItem = Block.Add(Source.Metadata().FullName());
				LockItem.SetValue("Ref", Source);
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
				
				DocumentObject = Source.GetObject(); // DocumentObject
				
				For Each FoundRow In FoundRows Do
					
					Filter = New Structure("RowID", FoundRow.SourceStringID);
					Rows = DocumentObject.Goods.FindRows(Filter);
					
					If Rows.Count() > 0 Then
						
						Rows[0].StoppedBeingReviewed = FoundRow.StoppedBeingReviewed;
						Rows[0].Comment       = FoundRow.Comment;
						
					EndIf;
					
				EndDo;
				
				DocumentObject.Write();
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				Cancel = True;
				
				WriteLogEvent(
					StrTemplate("%1.%2", NStr("vi = 'Báo giá.';
												|ru = 'Коммерческие предложения.';
												|en = 'Sales quotations.'; fa = 'Sales quotations.';
												|it = 'Proposte commerciali.';
												|pl = 'Oferty komercyjne.';
												|tr = 'Satış teklifleri.'", NStr("vi = 'Lưu tùy chỉnh';
																				|ru = 'Сохранение настроек';
																				|en = 'Saving settings'; fa = 'Saving settings';
																				|it = 'Salvataggio delle impostazioni';
																				|pl = 'Zapis ustawień';
																				|tr = 'Ayarları kaydet'")),
					Common.DefaultLanguageCode()), EventLogLevel.Error,, Source,
					NStr("vi = 'Yêu cầu lưu báo giá';
						|ru = 'Сохранение настроек запроса коммерческих предложений';
						|en = 'Save RFP (request for sales quotation) settings'; fa = 'Save RFP (request for sales quotation) settings';
						|it = 'Salvataggio delle impostazioni della richiesta di offerte commerciali';
						|pl = 'Zapisywanie ustawień zapytania ofert komercyjnych';
						|tr = 'Satış teklifi sorgu ayarları kaydediliyor'"));
					
				Return;
				
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the data of possible recipients of printed forms.
//
// Parameters:
//  FullMetadataObjectName  - String - the full name of the metadata object for which recipients are defined for printed forms.
//  PrintObjectDataStructure  - Structure - a description of the potential recipients
//
Procedure FillInStructureDataOfRecipientOfPrintedFormByObjectType(FullMetadataObjectName, PrintObjectDataStructure) Export
	
	If FullMetadataObjectName = "Document.CommercialProposalForCustomer" Then
		
		CommercialOfferToClientFillInStructureDataOfRecipientOfPrintedForm(PrintObjectDataStructure);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.ReceiveCommercialOffersToClientOnBasisOf.
//
Procedure ReceiveCommercialOffersToClientOnBasisOf(Val ObjectReference, CommercialOffersToClient) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CommercialProposalForCustomer.Ref AS Ref,
	|	CommercialProposalForCustomer.Number AS Number,
	|	CommercialProposalForCustomer.Date AS Date,
	|	CommercialProposalForCustomer.Manager AS Manager
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|WHERE
	|	CommercialProposalForCustomer.DocumentBasis = &DocumentBasis";
	
	Query.SetParameter("DocumentBasis", ObjectReference);
	
	QueryResult = Query.Execute();
	
	CommercialOffersToClient = QueryResult.Unload();
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenFillingInDataOfElectronicDocument.
//
Procedure WhenFillingInDataOfElectronicDocument(ObjectReference, PreparedData , StandardProcessing) Export
	
	DocumentBasis = Common.ObjectAttributeValue(ObjectReference, "DocumentBasis", True);
	
	If Not GetFunctionalOption("UseSets")
		Or (ValueIsFilled(DocumentBasis)
			And TypeOf(DocumentBasis) <> Type("DocumentRef.CommercialProposalForCustomer")) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED 
	|	Goods.LineNumber       AS LineNumber,
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	CASE
	|		WHEN Goods.UnitOfMeasure = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.Products.UnitOfMeasure
	|		ELSE Goods.UnitOfMeasure
	|	END                   AS UnitOfMeasure,
	|	Goods.Ref AS Ref
	|INTO DocumentGoods
	|FROM
	|	Document.CommercialProposalForCustomer.Goods AS Goods
	|WHERE
	|	Goods.Ref = &ObjectReference
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentGoods.LineNumber,
	|	DocumentGoods.ProductsInSet,
	|	DocumentGoods.ItemVariantOfSet,
	|	DocumentGoods.ProductsInSet.UnitOfMeasure,
	|	DocumentGoods.Ref
	|FROM
	|	Document.CommercialProposalForCustomer.Goods AS DocumentGoods
	|	INNER JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner      = DocumentGoods.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = DocumentGoods.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|		AND ProductKitConfigurations.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|WHERE
	|	DocumentGoods.Ref = &ObjectReference
	|	AND DocumentGoods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT DISTINCT
	|	Goods.Products AS Products
	|FROM
	|	DocumentGoods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT DISTINCT
	|	Goods.Characteristic AS Characteristic
	|FROM
	|	DocumentGoods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT DISTINCT
	|	Goods.UnitOfMeasure AS UnitOfMeasure
	|FROM
	|	DocumentGoods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT DISTINCT
	|	Goods.Products     AS Products,
	|	Goods.Characteristic   AS Characteristic,
	|	Goods.UnitOfMeasure AS UnitOfMeasure
	|FROM
	|	DocumentGoods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT ALLOWED
	|	CommercialOfferToClientGoods.Ref                                                                             AS Ref,
	|	CommercialOfferToClientGoods.LineNumber                                                                        AS LineNumber,
	|	CommercialOfferToClientGoods.RowIDRequest                                                         AS RowID,
	|	CommercialOfferToClientGoods.Products                                                                       AS Products,
	|	CommercialOfferToClientGoods.Characteristic                                                                     AS Characteristic,
	|	CASE
	|		WHEN CommercialOfferToClientGoods.UnitOfMeasure = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CommercialOfferToClientGoods.Products.UnitOfMeasure
	|		ELSE CommercialOfferToClientGoods.UnitOfMeasure
	|	END                                                                                                                   AS UnitOfMeasure,
	|	CommercialOfferToClientGoods.Count                                                                         AS Count,
	|	CommercialOfferToClientGoods.Price                                                                               AS Price,
	|	CommercialOfferToClientGoods.VATRate                                                                          AS VATRate,
	|	CommercialOfferToClientGoods.VATAmount                                                                           AS VATAmount,
	|	CommercialOfferToClientGoods.Sum                                                                              AS AmountExcludingVAT,
	|	CommercialOfferToClientGoods.AmountIncludingVAT                                                                          AS AmountIncludingVAT,
	|	CommercialOfferToClientGoods.ManualDiscount + CommercialOfferToClientGoods.DiscountMarkupAmount AS DiscountAmount,
	|	CASE
	|		WHEN CommercialOfferToClientGoods.PercentRateOfAutomaticDiscountMarkup = 0 AND CommercialOfferToClientGoods.PercentRateOfManualDiscount = 0 THEN 0
	|		WHEN CommercialOfferToClientGoods.PercentRateOfAutomaticDiscountMarkup <> 0 AND CommercialOfferToClientGoods.PercentRateOfManualDiscount <> 0 THEN -1
	|		WHEN CommercialOfferToClientGoods.PercentRateOfAutomaticDiscountMarkup <> 0 AND CommercialOfferToClientGoods.PercentRateOfManualDiscount = 0  THEN CommercialOfferToClientGoods.PercentRateOfAutomaticDiscountMarkup
	|		WHEN CommercialOfferToClientGoods.PercentRateOfAutomaticDiscountMarkup = 0 AND CommercialOfferToClientGoods.PercentRateOfManualDiscount <> 0 THEN CommercialOfferToClientGoods.PercentRateOfManualDiscount
	|	END                                                                                                                   AS DiscountPercentage,
	|	CommercialOfferToClientGoods.DeliveryPeriodDays                                                                       AS DeliveryPeriodDays,
	|	CommercialOfferToClientGoods.CommentForCustomer                                                           AS Comment,
	|	CommercialProposalForCustomer.OptionToSpecifyDeliveryTerm                                                             AS OptionToSpecifyDeliveryTerm,
	|
	|	ProductKitConfigurations.Ref                                                                                 AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms                                              AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption                                                               AS SetPricingOption,
	|	CommercialOfferToClientGoods.ProductsInSet                                                                 AS ProductsInSet,
	|	CommercialOfferToClientGoods.ItemVariantOfSet                                                               AS ItemVariantOfSet
	|
	|INTO Goods
	|FROM
	|	Document.CommercialProposalForCustomer.Goods AS CommercialOfferToClientGoods
	|		INNER JOIN Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|			ON CommercialOfferToClientGoods.Ref = CommercialProposalForCustomer.Ref
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|			ON ProductKitConfigurations.Owner      = CommercialOfferToClientGoods.ProductsInSet
	|			AND ProductKitConfigurations.Characteristic = CommercialOfferToClientGoods.ItemVariantOfSet
	|			AND ProductKitConfigurations.Main
	|WHERE
	|	CommercialOfferToClientGoods.Ref = &ObjectReference
	|;
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT
	|	Table.Ref                              AS Ref,
	|	Table.ProductsInSet                  AS ProductsInSet,
	|	Table.ItemVariantOfSet                AS ItemVariantOfSet,
	|	Table.ProductsInSet.UnitOfMeasure AS UnitOfMeasure,
	|	MIN(Table.LineNumber)                AS LineNumber,
	|	SUM(Table.AmountExcludingVAT)                  AS AmountExcludingVAT,
	|	SUM(Table.VATAmount)                     AS VATAmount,
	|	SUM(Table.AmountIncludingVAT)                    AS AmountIncludingVAT,
	|	SUM(Table.DiscountAmount)                  AS DiscountAmount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////8
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	Goods.DeliveryPeriodDays AS DeliveryPeriodDays,
	|	Goods.VATRate AS VATRate,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products                                     AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic                                   AS Characteristic,
	|	FALSE AS MainComponent,
	|	NULL AS DeliveryPeriodDays,
	|	NULL AS VATRate,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////9
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.VATRate) AS VATRate,
	|	MAX(Table.DeliveryPeriodDays) AS DeliveryPeriodDays,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////10
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.VATRate
	|			ELSE NULL
	|		END) AS VATRate,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.DeliveryPeriodDays
	|			ELSE NULL
	|		END) AS DeliveryPeriodDays,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////11
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration AS ProductConfigurationOptionProductConfigurationOption,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.KindsOfCommercialProposalProcedures.ConsignmentProcurement) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END                                                      AS PresentationOptionInPrintForms,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.KindsOfCommercialProposalProcedures.ConsignmentProcurement) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END                                                       AS SetPricingOption,
	|	Table.Ref                                              AS Ref,
	|	Table.ProductsInSet                                  AS ProductsInSet,
	|	Table.ItemVariantOfSet                                AS ItemVariantOfSet,
	|	Table.UnitOfMeasure                                    AS UnitOfMeasure,
	|	Table.LineNumber                                         AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.AmountExcludingVAT                                         AS AmountExcludingVAT,
	|	Table.VATAmount                                            AS VATAmount,
	|	Table.AmountIncludingVAT                                           AS AmountIncludingVAT,
	|	Table.DiscountAmount                                         AS DiscountAmount,
	|	TemporaryTableSetsOptional.DeliveryPeriodDays            AS DeliveryPeriodDays,
	|	TemporaryTableSetsOptional.VATRate               AS VATRate
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////12
	|SELECT
	|	
	|	Goods.Ref                                           AS Ref,
	|	Goods.PresentationOptionInPrintForms        AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                         AS SetPricingOption,
	|	Goods.ProductsInSet                               AS ProductsInSet,
	|	Goods.ItemVariantOfSet                             AS ItemVariantOfSet,
	|	Goods.IsRecordsSet                                         AS IsRecordsSet,
	|	Goods.TheseAreComponents                                 AS TheseAreComponents,
	|
	|	Goods.LineNumber                                      AS LineNumber,
	|	Goods.Products                                     AS Products,
	|	Goods.UnitOfMeasure                                 AS UnitOfMeasure,
	|	Goods.Count                                       AS Count,
	|
	|	Goods.Price AS Price,
	|
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.AmountExcludingVAT                                       AS AmountExcludingVAT,
	|	Goods.VATAmount                                          AS VATAmount,
	|	Goods.AmountIncludingVAT                                         AS AmountIncludingVAT,
	|	Goods.DeliveryPeriodDays                                      AS DeliveryPeriodDays,
	|	ISNULL(Goods.Characteristic, """")                    AS Characteristic,
	|	Goods.DiscountAmount                                       AS DiscountAmount,
	|	Goods.DiscountPercentage                                     AS DiscountPercentage,
	|	Goods.Comment                                       AS Comment,
	|	Goods.OptionToSpecifyDeliveryTerm                      AS OptionToSpecifyDeliveryTerm
	|
	|FROM (
	|
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.Price,
	|		Table.VATRate,
	|		Table.AmountExcludingVAT,
	|		Table.VATAmount,
	|		Table.AmountIncludingVAT,
	|		Table.DeliveryPeriodDays,
	|		Table.Characteristic,
	|		Table.UnitOfMeasure,
	|		Table.DiscountAmount,
	|		Table.DiscountPercentage,
	|		Table.Comment,
	|		Table.OptionToSpecifyDeliveryTerm
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		CASE WHEN ISNULL(TemporaryTableSets.Count, 1) <> 0 THEN
	|			(TemporaryTableSets.AmountIncludingVAT) / ISNULL(TemporaryTableSets.Count, 1)
	|		ELSE
	|			0
	|		END AS Price,
	|		TemporaryTableSets.VATRate,
	|		TemporaryTableSets.AmountExcludingVAT,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.AmountIncludingVAT,
	|		TemporaryTableSets.DeliveryPeriodDays,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		TemporaryTableSets.UnitOfMeasure,
	|		TemporaryTableSets.DiscountAmount,
	|		-1,
	|		"""",
	|		VALUE(Enum.DeliveryPeriodOptionsForCommercialProposals.EmptyRef) 
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|) AS Goods
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////13
	|SELECT ALLOWED
	|	CommercialProposalForCustomer.SKPIDInService                                                                           AS QueryID,
	|	CommercialProposalForCustomer.Status                                                                                             AS Status,
	|	CommercialProposalForCustomer.Posted                                                                                           AS Posted,
	|	CommercialProposalForCustomer.Ref                                                                                             AS Ref,
	|	CommercialProposalForCustomer.Organization                                                                                        AS Organization,
	|	CommercialProposalForCustomer.Counterparty                                                                                         AS Counterparty,
	|	CommercialProposalForCustomer.Manager                                                                                           AS Manager,
	|	Users.Description                                                                                                         AS ManagerPresentation,
	|	CommercialProposalForCustomer.DeliveryTermsText                                                                               AS DeliveryTerms,
	|	CommercialProposalForCustomer.PaymentTermsText                                                                                 AS PaymentTerm,
	|	CommercialProposalForCustomer.OtherAdditionalInformationText                                                                AS OtherConditions_,
	|	CommercialProposalForCustomer.BusinessOperation = VALUE(Enum.KindsOfCommercialProposalProcedures.ConsignmentProcurement) AS AcceptanceAndTransferToCommission,
	|	NOT CommercialProposalForCustomer.PartialSaleAllowed                                                                         AS AllOrNothing,
	|	CommercialProposalForCustomer.PriceIncludesVAT                                                                                    AS PriceIncludesVAT,
	|	CommercialProposalForCustomer.Currency.Code                                                                                         AS CurrencyCode,
	|	CommercialProposalForCustomer.Currency.Description                                                                                AS CurrencyName,
	|	NOT CommercialProposalForCustomer.Taxation                                                                                 AS USN,
	|	CommercialProposalForCustomer.ValidityPeriod                                                                                       AS ValidityPeriod,
	|	CommercialProposalForCustomer.AdditionalInformationToCustomerHTML                                                                AS AdditionalInformationToCustomerHTML
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|		LEFT JOIN Catalog.Currencies AS Currencies
	|		ON CommercialProposalForCustomer.Currency = Currencies.Ref
	|		LEFT JOIN Catalog.Users AS Users
	|		ON (Users.Ref = CommercialProposalForCustomer.Manager)
	|WHERE
	|	CommercialProposalForCustomer.Ref = &ObjectReference";
	
	Query.SetParameter("ObjectReference", ObjectReference);
	
	TMCommonUse.ShowTemporaryTable(Query, "DocumentGoods");
	TMCommonUse.ShowTemporaryTable(Query, "TemporaryTableSets");
	
	QueryResult = Query.ExecuteBatch();
	
	PreparedData.QueryResultProducts               = QueryResult[1];
	PreparedData.QueryResultCharacteristic             = QueryResult[2];
	PreparedData.QueryResultUnitsOfMeasurement           = QueryResult[3];
	PreparedData.QueryResultToGetBarcode     = QueryResult[4];
	PreparedData.QueryResultGoods                     = QueryResult[12];
	PreparedData.QueryResultHeader                      = QueryResult[13];
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenFillingInComparisonParametersItIsRequestedThat.
//
Procedure WhenFillingInComparisonParametersItIsRequestedThat(Parameters, QueryStringData, CurrentRowData) Export
	
	If Not ValueIsFilled(CurrentRowData.UnitOfMeasure)
		And ValueIsFilled(CurrentRowData.Products) Then
		
		Parameters.UnitOfMeasure = Common.ObjectAttributeValue(CurrentRowData.Products, "UnitOfMeasure");
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.AfterAddingLinesFromRequestToCommercialOfferToClient.
//
Procedure AfterAddingLinesFromRequestToCommercialOfferToClient(Form, ArrayOfIDsOfAddedRows) Export
	
	Object = Form.Object;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.Date = CurrentSessionDate();
	ParametersForFillingInVATRate.VATTaxation = Form.VATTaxation;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	RowsToProcess = New Array();
	
	For Each ArrayElement In ArrayOfIDsOfAddedRows Do
		SearchParameters = New Structure;
		SearchParameters.Insert("RowIDRequest", ArrayElement);
		FoundRows = Object.Goods.FindRows(SearchParameters);
		If FoundRows.Count() = 1 Then
			
			RowsToProcess.Add(FoundRows[0]);
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.GetTextOfRequestToGetUnitOfMeasurement.
//
Procedure GetTextOfRequestToGetUnitOfMeasurement(QueryText) Export
	
	QueryText =
	"	CASE
	|		WHEN Goods.UnitOfMeasure = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN Goods.Products.UnitOfMeasure
	|		ELSE Goods.UnitOfMeasure
	|	END";
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.CommercialOfferToClientWhenFormingPrintDataStructure.
//
Procedure CommercialOfferToClientWhenFormingPrintDataStructure(ObjectsArray, DataStructureForPrinting, PrintParameters, StandardProcessing) Export
	
	If Not GetFunctionalOption("UseSets") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Query = New Query;
	Query.SetParameter("ObjectsArray",   ObjectsArray);
	
	DisplayDiscounts_ = True;
	If PrintParameters.Property("DisplayDiscounts_")
		And Not PrintParameters.DisplayDiscounts_ Then
		DisplayDiscounts_ = False;
	EndIf;
	
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	
	Query.Text = "
	|SELECT
	|	CommercialProposalForCustomer.Ref                              AS Ref,
	|	CommercialProposalForCustomer.Date                                AS Date,
	|	CommercialProposalForCustomer.Number                               AS Number,
	|	CommercialProposalForCustomer.Manager                            AS Manager,
	|	CommercialProposalForCustomer.ContactPerson                      AS ContactPerson,
	|	CommercialProposalForCustomer.Organization                         AS Organization,
	|	CommercialProposalForCustomer.ValidityPeriod                        AS ValidityPeriod,
	|	CommercialProposalForCustomer.Currency                              AS Currency,
	|	CommercialProposalForCustomer.PriceIncludesVAT                     AS PriceIncludesVAT,
	|	CommercialProposalForCustomer.Taxation                     AS ConsiderVAT,
	|	CommercialProposalForCustomer.DeliveryTermsText                AS DeliveryTerms,
	|	CommercialProposalForCustomer.PaymentTermsText                  AS PaymentTerm,
	|	CommercialProposalForCustomer.OtherAdditionalInformationText AS OtherConditions,
	|	CommercialProposalForCustomer.Client                              AS Client,
	|	CommercialProposalForCustomer.Counterparty                          AS Counterparty,
	|	CommercialProposalForCustomer.OptionToSpecifyDeliveryTerm        AS OptionToSpecifyDeliveryTerm,
	|	CommercialProposalForCustomer.PartialSaleAllowed             AS PartialSaleAllowed
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|WHERE
	|	CommercialProposalForCustomer.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT
	|	GoodsTable.Ref                                                          AS Ref,
	|	GoodsTable.LineNumber                                                     AS LineNumber,
	|	GoodsTable.Products                                                    AS Products,
	|	GoodsTable.Characteristic                                                  AS Characteristic,
	|	GoodsTable.ManualDiscount + GoodsTable.DiscountMarkupAmount     AS DiscountAmount,
	|	GoodsTable.PercentRateOfManualDiscount + GoodsTable.PercentRateOfAutomaticDiscountMarkup AS DiscountPercentage,
	|	CASE
	|		WHEN GoodsTable.UnitOfMeasure = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.UnitOfMeasure
	|	END                                                                         AS UnitOfMeasure,
	|	GoodsTable.Count                                                      AS Count,
	|	CASE
	|		WHEN &DisplayDiscounts_
	|			THEN GoodsTable.Price
	|		ELSE CASE
	|			WHEN GoodsTable.Count = 0
	|				THEN 0
	|			ELSE GoodsTable.Sum / GoodsTable.Count
	|		END
	|	END                                                                         AS Price,
	|	GoodsTable.AmountIncludingVAT                                                       AS AmountIncludingVAT,
	|	GoodsTable.Sum                                                           AS Sum,
	|	GoodsTable.VATAmount                                                        AS VATAmount,
	|	GoodsTable.VATRate                                                       AS VATRate,
	|	GoodsTable.DeliveryPeriodDays                                                    AS DeliveryPeriodDays,
	|
	|	ProductKitConfigurations.Ref                                       AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms    AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption                     AS SetPricingOption,
	|	GoodsTable.ProductsInSet                                              AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet                                            AS ItemVariantOfSet
	|
	|INTO Goods
	|FROM
	|	Document.CommercialProposalForCustomer.Goods AS GoodsTable
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner      = GoodsTable.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = GoodsTable.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount,
	|	SUM(Table.AmountIncludingVAT)       AS AmountIncludingVAT,
	|	SUM(Table.DiscountAmount)     AS DiscountAmount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	Goods.DeliveryPeriodDays AS DeliveryPeriodDays,
	|	Goods.VATRate AS VATRate,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	NULL AS DeliveryPeriodDays,
	|	NULL AS VATRate,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.VATRate) AS VATRate,
	|	MAX(Table.DeliveryPeriodDays) AS DeliveryPeriodDays,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.VATRate
	|			ELSE NULL
	|		END) AS VATRate,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.DeliveryPeriodDays
	|			ELSE NULL
	|		END) AS DeliveryPeriodDays,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration AS ProductConfigurationOptionProductConfigurationOption,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.KindsOfCommercialProposalProcedures.ConsignmentProcurement) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END                                                      AS PresentationOptionInPrintForms,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.KindsOfCommercialProposalProcedures.ConsignmentProcurement) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END                                                       AS SetPricingOption,
	|	Table.Ref                                              AS Ref,
	|	Table.ProductsInSet                                  AS ProductsInSet,
	|	Table.ItemVariantOfSet                                AS ItemVariantOfSet,
	|	Table.LineNumber                                         AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                                               AS Sum,
	|	Table.VATAmount                                            AS VATAmount,
	|	Table.AmountIncludingVAT                                           AS AmountIncludingVAT,
	|	Table.DiscountAmount                                         AS DiscountAmount,
	|	TemporaryTableSetsOptional.DeliveryPeriodDays            AS DeliveryPeriodDays,
	|	TemporaryTableSetsOptional.VATRate               AS VATRate
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////8
	|SELECT
	|	
	|	Goods.Ref                                           AS Ref,
	|	Goods.PresentationOptionInPrintForms        AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                         AS SetPricingOption,
	|	Goods.ProductsInSet                               AS ProductsInSet,
	|	Goods.ItemVariantOfSet                             AS ItemVariantOfSet,
	|	Goods.IsRecordsSet                                         AS IsRecordsSet,
	|	Goods.TheseAreComponents                                 AS TheseAreComponents,
	|
	|	Goods.LineNumber                                      AS LineNumber,
	|	Goods.Products                                     AS Products,
	|	Goods.UnitOfMeasure                                 AS UnitOfMeasure,
	|	Goods.Count                                       AS Count,
	|
	|	Goods.Price AS Price,
	|
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	Goods.AmountIncludingVAT                                         AS AmountIncludingVAT,
	|	Goods.DeliveryPeriodDays                                      AS DeliveryPeriodDays,
	|	ISNULL(Goods.Characteristic, """")                    AS Characteristic,
	|	Goods.DiscountAmount                                       AS DiscountAmount
	|
	|FROM (
	|
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATRate,
	|		Table.VATAmount,
	|		Table.AmountIncludingVAT,
	|		Table.DeliveryPeriodDays,
	|		Table.Characteristic,
	|		Table.UnitOfMeasure,
	|		Table.DiscountAmount
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		CASE
	|			WHEN &DisplayDiscounts_ THEN
	|				CASE WHEN ISNULL(TemporaryTableSets.Count, 1) <> 0 THEN
	|					(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.Count, 1)
	|				ELSE
	|					0
	|				END
	|			ELSE
	|				CASE WHEN ISNULL(TemporaryTableSets.Count, 1) <> 0 THEN
	|					(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.Count, 1)
	|				ELSE
	|					0
	|				END
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.AmountIncludingVAT,
	|		TemporaryTableSets.DeliveryPeriodDays,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		TemporaryTableSets.ProductsInSet.UnitOfMeasure,
	|		TemporaryTableSets.DiscountAmount
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                                        VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Goods
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
	|";
	
	UnitConditions = "Goods.UnitOfMeasure";
	CommercialProposalsDocumentsOverridable.GetTextOfRequestToGetUnitOfMeasurement(UnitConditions);
	Query.Text = StrReplace(Query.Text, "&UnitConditions", UnitConditions);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",        RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByProducts",      RequestResultsPackage[8]);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.AddObjectDataForPrinting.
//
Procedure AddObjectDataForPrinting(RowOfProductsTable, LineProducts_, ObjectData) Export
	
	If Not GetFunctionalOption("UseSets") Then
		Return;
	EndIf;
	
	RowOfProductsTable.Insert("PresentationOptionInPrintForms", LineProducts_.PresentationOptionInPrintForms);
	RowOfProductsTable.Insert("SetPricingOption",                  LineProducts_.SetPricingOption);
	RowOfProductsTable.Insert("TheseAreComponents",                          LineProducts_.TheseAreComponents);
	RowOfProductsTable.Insert("IsRecordsSet",                                  LineProducts_.IsRecordsSet);
	
	If Not ValueIsFilled(LineProducts_.ProductsInSet) Then
		Return;
	EndIf;
	
	If LineProducts_.IsRecordsSet
		And LineProducts_.PresentationOptionInPrintForms <> Enums.OptionsOfSetPresentationInPrintForms.OnlySet Then
		
		ObjectData.GoodsQuantity = ObjectData.GoodsQuantity - 1;
		ObjectData.AmountTotal        = ObjectData.AmountTotal    - LineProducts_.Sum;
		ObjectData.AmountTotalVAT     = ObjectData.AmountTotalVAT - LineProducts_.VATAmount;
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.FillInOrganizationData.
//
Procedure FillInOrganizationData(Val Organization, InformationRecords) Export
	
	DateOfLastEdit = CurrentSessionDate();
	CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(Organization, DateOfLastEdit);
	FillPropertyValues(InformationRecords, CompanyInformation);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.UponReceiptOfPresentationOfCounterpartySPartner.
//
Procedure UponReceiptOfPresentationOfCounterpartySPartner(PresentationOfCounterpartySPartner, Partner, Counterparty, StandardProcessing) Export
	
	StandardProcessing = False;
	
	If ValueIsFilled(Counterparty) Then
		PresentationOfCounterpartySPartner = Counterparty.DescriptionFull;
	ElsIf ValueIsFilled(Partner) Then
		PresentationOfCounterpartySPartner = Partner.DescriptionFull;
	Else
		StandardProcessing = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region AccessManagement

// See CommercialProposalsDocumentsOverridable.OnFillMetadataObjectsAccessRestrictionKinds.
//
Procedure OnFillMetadataObjectsAccessRestrictionKinds(ObjectName, LongDesc) Export
	
	If ObjectName = "Document.CommercialProposalForCustomer" Then
		
		LongDesc = LongDesc + "
		|Document.CommercialProposalForCustomer.Read.Companies
		|Document.CommercialProposalForCustomer.Update.Companies
		|Document.CommercialProposalForCustomer.Read.PartnerGroups
		|Document.CommercialProposalForCustomer.Update.PartnerGroups
		|";
		
	ElsIf ObjectName = "Catalog.CommercialProposalForCustomerAttachedFiles" Then
		
		LongDesc = LongDesc + "
		|Catalog.CommercialProposalForCustomerAttachedFiles.Read.Companies
		|Catalog.CommercialProposalForCustomerAttachedFiles.Update.Companies
		|Catalog.CommercialProposalForCustomerAttachedFiles.Read.PartnerGroups
		|Catalog.CommercialProposalForCustomerAttachedFiles.Update.PartnerGroups
		|";
		
	EndIf;
	
	CommercialProposalsDocumentsLocalization.OnFillMetadataObjectsAccessRestrictionKinds(ObjectName, LongDesc)
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.OnFillAccessRestriction.
//
Procedure OnFillAccessRestriction(ObjectName, Restriction) Export
	
	If ObjectName = "Document.CommercialProposalForCustomer" Then
		
		Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	ValueAllowed(Organization)
		|	AND ValueAllowed(Client)";
		
	ElsIf ObjectName = "Catalog.CommercialProposalForCustomerAttachedFiles" Then
		
		Restriction.Text =
		"AllowRead
		|WHERE
		|	ObjectReadingAllowed(FileOwner)
		|;
		|AllowUpdateIfReadingAllowed
		|WHERE
		|	ObjectUpdateAllowed(FileOwner)";
		
	EndIf;
		
	CommercialProposalsDocumentsLocalization.OnFillAccessRestriction(ObjectName, Restriction);
	
EndProcedure

#EndRegion

#Region FormEventHandlers

// See CommercialProposalsDocumentsOverridable.OnCreateAtServer
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export 
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenCreatedOnServer(Form, Cancel, StandardProcessing);
		
	ElsIf Form.FormName = "Document.CommercialProposalForCustomer.Form.ListForm" Then
		
		Form.Items.CreateBasedOnSubmenu.Picture = PictureLib.FillFromTemplate;
		
	EndIf;

	CommercialProposalsDocumentsLocalization.OnCreateAtServer(Form, Cancel, StandardProcessing);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.OnReadAtServer.
//
Procedure OnReadAtServer(Form, CurrentObject) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenReadingOnServer(Form, CurrentObject);
		
	EndIf;
	
	ConfigurationModificationOverridable.OnReadAtServer(Form, CurrentObject);

EndProcedure

// See CommercialProposalsDocumentsOverridable.AfterWriteAtServer.
//
Procedure AfterWriteAtServer(Form, CurrentObject) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientAfterRecordingOnServer(Form, CurrentObject);
		
	EndIf;

	CommercialProposalsDocumentsLocalization.AfterWriteAtServer(Form, CurrentObject);	

EndProcedure

// See CommercialProposalsDocumentsOverridable.FillCheckProcessing.
//
Procedure FillCheckProcessing(DocumentObject, Cancel, CheckedAttributes, NotCheckedAttributeArray) Export
	
	If TypeOf(DocumentObject) = Type("DocumentObject.CommercialProposalForCustomer") Then
		
		CommercialOfferToClientProcessingFillCheckOnServer(DocumentObject, Cancel, CheckedAttributes, NotCheckedAttributeArray);
		
	EndIf;

	CommercialProposalsDocumentsLocalization.FillCheckProcessing(DocumentObject, Cancel, CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.Posting.
//
Procedure Posting(DocumentObject, Cancel, PostingMode) Export

	CommercialProposalsDocumentsLocalization.Posting(DocumentObject, Cancel, PostingMode);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.UndoPosting.
//
Procedure UndoPosting(DocumentObject, Cancel) Export

	CommercialProposalsDocumentsLocalization.UndoPosting(DocumentObject, Cancel);	
	
EndProcedure

#EndRegion

#Region DocumentEventHandlers

// See CommercialProposalsDocumentsOverridable.OnWrite.
//
Procedure OnWrite(DocumentObject, Cancel) Export
	
	If TypeOf(DocumentObject) = Type("DocumentObject.CommercialProposalForCustomer") Then
		
		EventProcessingWhenRecordingCommercialOfferToClient(DocumentObject, Cancel);
		
	EndIf;
	
	CommercialProposalsDocumentsLocalization.OnWrite(DocumentObject, Cancel);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.BeforeWrite.
//
Procedure BeforeWrite(DocumentObject, Cancel, WriteMode, PostingMode) Export
	
	CommercialProposalsDocumentsLocalization.BeforeWrite(DocumentObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

// Called when copying a document.
//
// Parameters:
//  DocumentObject - DocumentObject - The document to be filled in.
Procedure OnCopy(DocumentObject) Export
	
	DocumentObject.DocumentBasis = Undefined;
	DocumentObject.SKPIDInService = Undefined;
	
	For Each RowOfGoods In DocumentObject.Goods Do
		
		RowOfGoods.RowIDRequest = Undefined;
		RowOfGoods.IDForItemMapping = Undefined;
		RowOfGoods.CustomerProductsID = Undefined;
		RowOfGoods.CustomerProductsPresentation = Undefined;
		RowOfGoods.ProductsInIDService = Undefined;
		RowOfGoods.CharacteristicInIDService = Undefined;
		
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(DocumentObject);
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(DocumentObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(DocumentObject.Goods, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		DocumentObject.Goods,
		CachedValues);
		
EndProcedure

#EndRegion

#Region ConditionalAppearance

// See CommercialProposalsDocumentsOverridable.WhenSettingConditionalAppearance
//
Procedure WhenSettingConditionalAppearance(Form) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenInstallingConditionalAppearance(Form);
		
	EndIf;

	CommercialProposalsDocumentsLocalization.WhenSettingConditionalAppearance(Form);	
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenDefiningAccountingSettings
//
Procedure WhenDefiningAccountingSettings(Settings) Export
	
	SetPrivilegedMode(True);
	
	If Not Catalogs.Companies.MultipleOrganizationsAreUsed() Then
		Settings.SingleOrganizationIsUsed = True;
		Settings.SoleCompany = Catalogs.Companies.DefaultCompany();
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		Settings.SingleCurrencyIsUsed = True;
		Settings.OnlyCurrency = SettingsValueCached.DefaultBaseCurrency();
		
	EndIf;
	
	Settings.PartnersAreUsed = True;
	Settings.IndependentManagementOfPartnersAndCounterparties             = GetFunctionalOption("UsePartnersAndCounterparties");
	Settings.ProductCharacteristicsAreUsed               = GetFunctionalOption("UseItemVariants");
	Settings.TypesOfPricesAreUsed                                  = True;
	Settings.ManualDiscountsAreUsedInSales                    = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	Settings.AutomaticDiscountsInSalesAreUsed            = GetFunctionalOption("UseDiscountsMarkupsInSales");
	Settings.AssignableAutomaticDiscountsInSalesAreUsed = GetFunctionalOption("UseDiscountsMarkupsInSales");
	Settings.SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments = GetFunctionalOption("UseDiscountsMarkupsInSales");
	Settings.DoNotDisplayDiscountsInSalesDocuments                    = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
	                                                                  = Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	Settings.ImplementedFormForViewingDiscounts                      = GetFunctionalOption("UseDiscountsMarkupsInSales");
	Settings.ImplementedFillingInPricesAccordingToSalesConditions             = True;
	Settings.ImplementedFillingPricesByTypeOfPrices                   = True;
	Settings.ImplementedFillingInPaymentTerms                   = True;
	Settings.ImplementedSelectionOfProducts                         = True;
	Settings.ImplementedBarcodeSearch                           = True;
	Settings.ImplementedStringSplitting                            = True;
	Settings.ImplementedLoadingTSDData                         = True;
	Settings.ImplementedFillingInDocumentsFromExternalFile       = True;
	Settings.StatusOfCommercialOffersToClientsIsUsed   = True;
	Settings.StatesOfCommercialOffersToClientsAreUsed = True;
	Settings.RegisterSupplierPrices                        = True;
	Settings.DetailsOfCounterpartySProductOwner         = "Client";

	StatusesOfCommercialOffersToCustomersAreValid = Settings.StatusesOfCommercialOffersToCustomersAreValid; // Array
	StatusesOfCommercialOffersToCustomersAreValid.Add(Enums.StatusesOfCommercialProposalsForCustomers.Valid);
	
	StatusOfCommercialOffersToClientsDraft = Settings.StatusOfCommercialOffersToClientsDraft; // Array
	StatusOfCommercialOffersToClientsDraft.Add(Enums.StatusesOfCommercialProposalsForCustomers.Draft);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.EstablishConditionalAppearanceOfProductCharacteristics.
//
Procedure EstablishConditionalAppearanceOfProductCharacteristics(Form, NameOfCharacteristicInputField, PathToSelectionField) Export
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(Form);
	
EndProcedure 

#EndRegion

#Region ServerSideEventHandlersForFormElements

// See CommercialProposalsDocumentsOverridable.OnCreateAtServer.
//
Procedure WhenChangingPartner(Form) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenPartnerChanges(Form);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.OnCreateAtServer.
//
Procedure WhenChangingVATTaxation(Form) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientInCaseOfChangesInVATTaxation(Form);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.OnChangePriceIncludesVAT.
//
Procedure OnChangePriceIncludesVAT(Form, Taxation) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingPriceIncludesVAT(Form, Taxation);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenChangingCurrency.
//
Procedure WhenChangingCurrency(Form) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingCurrency(Form);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenOrganizationChanges.
//
Procedure WhenOrganizationChanges(Form) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenOrganizationChanges(Form);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenOrganizationChanges.
//
Procedure WhenBusinessTransactionChanges(Form) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientInCaseOfChangeOfBusinessOperation(Form);
		
	EndIf;
	
EndProcedure

#EndRegion

// See CommercialProposalsDocumentsOverridable.WhenDisplayingBarCodeInPrintedForms
//
Procedure WhenDisplayingBarCodeInPrintedForms(SpreadsheetDocument, Template, TemplateArea, PrintData) Export
	
	HeaderArea_ = Template.GetArea("Title");
	BarcodePrintingData = PrintData; // Structure
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, BarcodePrintingData.Ref);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenFormingTitleOfPrintedForm.
//
Procedure WhenFormingTitleOfPrintedForm(Template, TemplateArea, ObjectData) Export
	
	PrintFormGeneration.PrintLogoInTabularDocument(Template, TemplateArea, "TitleLogo", ObjectData.Organization);
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenDisplayingLineInPrintedForm
//
// Parameters:
//  SpreadsheetDocument              - SpreadsheetDocument
//  LineProducts_                   - ValueTableRow
//  AreaRowOfProductsTable     - SpreadsheetDocument
//  NamedAreaStringProducts - String
//  AdditionalOutputParameters  - Undefined
//  StandardProcessing           - Boolean
//
Procedure WhenDisplayingLineInPrintedForm(SpreadsheetDocument, LineProducts_, AreaRowOfProductsTable, NamedAreaStringProducts, AdditionalOutputParameters, StandardProcessing) Export
	
	If Not GetFunctionalOption("UseSets") Then 
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If AdditionalOutputParameters = Undefined Then
		 AdditionalOutputParameters = New Structure;
	EndIf;
	
	If Not AdditionalOutputParameters.Property("LineNumber")  Then
		 AdditionalOutputParameters.Insert("LineNumber", 0);
	EndIf;
	
	If SetsServer.UseSetArea(LineProducts_, True) Then
		
		If LineProducts_.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents Then
			
			If LineProducts_.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
			
				RowData = New Structure;
				RowData.Insert("LineNumber",      "");
				RowData.Insert("Products",     "");
				RowData.Insert("Count",       "");
				RowData.Insert("UnitOfMeasure", "");
				RowData.Insert("DeliveryPeriodDays",     "");
				RowData.Insert("Price",             "");
				RowData.Insert("DiscountAmount",      "");
				RowData.Insert("AmountIncludingVAT",        "");
			
				AreaRowOfProductsTable.Parameters.Fill(RowData);
				AreaRowOfProductsTable.Parameters.Products = LineProducts_.Products;
				
			Else
				
				FillPropertyValues(AreaRowOfProductsTable.Parameters, LineProducts_);
				
			EndIf;
			
		Else
			
			AdditionalOutputParameters.LineNumber = AdditionalOutputParameters.LineNumber + 1;
			AreaRowOfProductsTable.Parameters.LineNumber = AdditionalOutputParameters.LineNumber;
			
		EndIf;
		
		AreaRowOfProductsTable.Areas[NamedAreaStringProducts].TopBorder = New Line(SpreadsheetDocumentCellLineType.Solid,1, 0);
		AreaRowOfProductsTable.Areas[NamedAreaStringProducts].BottomBorder = New Line(SpreadsheetDocumentCellLineType.None);
		SpreadsheetDocument.Put(AreaRowOfProductsTable);
		
	ElsIf SetsServer.UseScope(LineProducts_, True) Then
		
		AdditionalOutputParameters.LineNumber = AdditionalOutputParameters.LineNumber + 1;
		
		If LineProducts_.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents Then
			
			If LineProducts_.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
				
				FillPropertyValues(AreaRowOfProductsTable.Parameters, LineProducts_);
				
			Else
				
				RowData = New Structure;
				RowData.Insert("LineNumber",      "");
				RowData.Insert("Products",     "");
				RowData.Insert("Count",       "");
				RowData.Insert("UnitOfMeasure", "");
				RowData.Insert("DeliveryPeriodDays",     "");
				RowData.Insert("Price",             "");
				RowData.Insert("DiscountAmount",      "");
				RowData.Insert("AmountIncludingVAT",        "");
			
				AreaRowOfProductsTable.Parameters.Fill(RowData);
				LineProducts_.Products = StrTemplate(NStr("vi = '%1, %2 %3';
															|ru = '%1, %2 %3';
															|en = '%1, %2 %3'; fa = '%1, %2 %3';
															|it = '%1, %2 %3';
															|pl = '%1, %2 %3';
															|tr = '%1, %2 %3'"), LineProducts_.Products, LineProducts_.Count, LineProducts_.UnitOfMeasure);
				
			EndIf;
			
		Else
			
			FillPropertyValues(AreaRowOfProductsTable.Parameters, LineProducts_);
			
		EndIf;
		
		AreaParameters_ = AreaRowOfProductsTable.Parameters; // SpreadsheetDocumentTemplateParameters
		AreaParameters_.LineNumber = AdditionalOutputParameters.LineNumber;
		AreaRowOfProductsTable.Parameters.Products = " - " + LineProducts_.Products;
		
		AreaRowOfProductsTable.Areas[NamedAreaStringProducts].TopBorder = New Line(SpreadsheetDocumentCellLineType.None);
		
		SpreadsheetDocument.Put(AreaRowOfProductsTable);
		
	Else
		
		AdditionalOutputParameters.LineNumber = AdditionalOutputParameters.LineNumber + 1;
		
		FillPropertyValues(AreaRowOfProductsTable.Parameters, LineProducts_);
		AreaRowOfProductsTable.Parameters.LineNumber = AdditionalOutputParameters.LineNumber;
		
		AreaRowOfProductsTable.Areas[NamedAreaStringProducts].TopBorder = New Line(SpreadsheetDocumentCellLineType.Solid,1, 0);
		AreaRowOfProductsTable.Areas[NamedAreaStringProducts].BottomBorder = New Line(SpreadsheetDocumentCellLineType.Solid,1, 0);
		
		SpreadsheetDocument.Put(AreaRowOfProductsTable);
		
		Return;
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenPastingLinesFromClipboard
//
Procedure WhenPastingLinesFromClipboard(Form, RowsCount, StandardProcessing) Export
	
	AccountingSettings                    = CommercialProposalsDocuments.AccountingSettings();
	
	Object = Form.Object; // DocumentObject.CommercialProposalForCustomer
	
	StandardProcessing = False;
	BufferData = ProcessingOfTabularForms.RowsFromClipboard();
	If Not ValueIsFilled(BufferData) Then
		Return;
	EndIf;
	
	UseSets = GetFunctionalOption("UseSets");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ActionParameters =  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ActionParameters.VATTaxation = Form.VATTaxation;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_",             New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate",                          ActionParameters);
		
	ParametersFillInVATRate =  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.VATTaxation = Form.VATTaxation;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount",                            "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",         
		New Structure("Clear, QuantityName", False, "Count"));
	If BufferData.Columns.Find("ManualDiscount") <> Undefined Then
		StructureOfActions.RecalculateAmountTakingIntoAccountManualDiscount.Insert("RecalculateAmountOfManualDiscount_", False);
	EndIf;
		
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", 
		New Structure("Clear, QuantityName", True, "Count"));
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	For Each RowOfProduct In BufferData Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		If BufferData.Columns.Find("Package") <> Undefined Then
			CurrentRow.UnitOfMeasure = RowOfProduct.Package;
		EndIf;
		If BufferData.Columns.Find("NumberOfPackages") <> Undefined Then
			//@skip-warning
			CurrentRow.QuantityIsTemporary = RowOfProduct.Count;
			CurrentRow.Count = RowOfProduct.NumberOfPackages;
		EndIf;
		
		If UseSets Then
			//@skip-warning
			CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		EndIf;
		If Not AccountingSettings.ManualDiscountsAreUsedInSales Then
			CurrentRow.PercentRateOfManualDiscount = 0;
			CurrentRow.ManualDiscount = 0;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	RowsCount = BufferData.Count();
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenCopyingLinesToClipboard.
//
Procedure WhenCopyingLinesToClipboard(Form, TabularSection, SelectedRows, TabularSectionName, StandardProcessing) Export
	
	StandardProcessing = False;
	
	ProcessingOfTabularForms.CopyRowsToClipboard(TabularSection, SelectedRows);
	
EndProcedure

#EndRegion

#Region Private

#Region CommercialProposalForCustomer

Procedure CommercialOfferToClientWhenPartnerChanges(Form)
	
	Object = Form.Object;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Client, Object.Counterparty);
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Client, Object.ContactPerson);
	
	ResponsiblePersonsServer.FillInManager_(Object, , "Client.MainManager");
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.OnCreateAtServer
//
// Parameters:
//  Form - ClientApplicationForm
//  Cancel - Boolean
//  StandardProcessing - Boolean
//
Procedure CommercialOfferToClientWhenCreatedOnServer(Form, Cancel, StandardProcessing)
	
	Object = Form.Object; // DocumentObject
	
	InfobaseUpdate.CheckObjectProcessed(Object, Form);
	
	If Object.Ref.IsEmpty() Then
		CommercialOfferToClientWhenCreatingReadingOnServer(Form);
	EndIf;
	
#Region ChoiceParameterLinks

	// Counterparty
	NewLinks = New Array;
	NewLinks.Add(New ChoiceParameterLink("Filter.Partner", "Object.Client"));
	Form.Items.Counterparty.ChoiceParameterLinks = New FixedArray(NewLinks);
	
	// Contact person 
	NewLinks = New Array;
	NewLinks.Add(New ChoiceParameterLink("Filter.Owner", "Object.Client"));
	Form.Items.ContactPerson.ChoiceParameterLinks = New FixedArray(NewLinks);
	
	// Unit
	NewLinks = New Array;
	NewLinks.Add(New ChoiceParameterLink("Products", "Items.Goods.CurrentData.Products", LinkedValueChangeMode.DontChange));
	Form.Items.GoodsUnitOfMeasure.ChoiceParameterLinks = New FixedArray(NewLinks);
	
	// Type of price
	NewLinks = New Array;
	NewLinks.Add(New ChoiceParameterLink("Filter.PriceIncludesVAT", "Object.PriceIncludesVAT"));
	Form.Items.GoodsPriceKind.ChoiceParameterLinks = New FixedArray(NewLinks);
	
#EndRegion

#Region ChoiceParameters
	
	// Partner
	NewParameters = New Array;
	NewParameters.Add(New ChoiceParameter("Filter.Client", True));
	Form.Items.Client.ChoiceParameters = New FixedArray(NewParameters);
	
	// Counterparty
	NewParameters = New Array;
	NewParameters.Add(New ChoiceParameter("TitleByPartner", NStr("vi = 'Theo khách hàng';
																|ru = 'По клиенту';
																|en = 'By customer'; fa = 'بر اساس مشتری';
																|it = 'Per cliente';
																|pl = 'Przez klienta';
																|tr = 'Müşteriye göre'")));
	Form.Items.Counterparty.ChoiceParameters = New FixedArray(NewParameters);
	
	// Products
	NewParameters = New Array;
	
	ArrayOfProductTypes = ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False);
	
	NewParameters.Add(New ChoiceParameter("Filter.ItemsType", ArrayOfProductTypes));
	Form.Items.GoodsProducts.ChoiceParameters = New FixedArray(NewParameters);
	
	// Type of price
	NewParameters = New Array;
	NewParameters.Add(New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True));
	NewParameters.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
	NewParameters.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
	Form.Items.GoodsPriceKind.ChoiceParameters = New FixedArray(NewParameters);
	
#EndRegion

#Region ManagingDisplayOfBankingDetails
	
	Form.Items.GoodsAmountIncludingVAT.ReadOnly                   = True;
	Form.Items.GoodsUnitOfMeasure.AutoMarkIncomplete = False;
	
#EndRegion

#Region AddingFormElements

	AddUnitFormElement(Form);
	
	FormCommand = Form.Commands.Add("ShowMessages");
	FormCommand.Title   = NStr("vi = 'Có thông báo';
								|ru = 'Есть сообщения';
								|en = 'There are messages'; fa = 'پیام وجود دارد';
								|it = 'Ci sono messaggi';
								|pl = 'Istnieją wiadomości';
								|tr = 'Mesaj mevcut'");
	FormCommand.Action    = "Attachable_OverriddenCommand";
	FormCommand.Picture    = PictureLib.Warning;
	
	Item             = Form.Items.Add("ShowMessages", Type("FormButton"), Form.Items.GroupCustomerCounterparty);
	Item.Type         = FormButtonType.Hyperlink;
	Item.CommandName  = "ShowMessages";
	
#Region SalesOpportunity

	If GetFunctionalOption("UseSalesOpportunitiesToCustomer") Then
		
		Item = Form.Items.Insert("SalesOpportunity", Type("FormField"), Form.Items.AdditionallyRightGroup, Form.Items.Organization);
		Item.DataPath            = "Object.SalesOpportunity";
		Item.Type                    = FormFieldType.InputField;
		Item.AutoMaxWidth = False;
		Item.MaxWidth     = 28;
		
		NewLinks = New Array;
		NewLinks.Add(New ChoiceParameterLink("Filter.Partner", "Object.Client"));
		Item.ChoiceParameterLinks = New FixedArray(NewLinks);
		
	EndIf;

#EndRegion

#Region LoyaltyCard

	If GetFunctionalOption("UseLoyaltyCards") Then
		
		Item = Form.Items.Insert("LoyaltyCard", Type("FormField"), Form.Items.AdditionallyRightGroup, Form.Items.TheDecorationIsAdditionallyRightEmpty);
		Item.DataPath            = "Object.LoyaltyCard";
		Item.Type                    = FormFieldType.InputField;
		Item.AutoMaxWidth = False;
		Item.MaxWidth     = 28;
		
		NewLinks = New Array;
		NewLinks.Add(New ChoiceParameterLink("Filter.Partner", "Object.Client"));
		Item.ChoiceParameterLinks = New FixedArray(NewLinks);
		
	EndIf;

#EndRegion	
	
#Region Sets

	UseSets = GetFunctionalOption("UseSets");

	If UseSets
		And Not Form.OnRequest Then
	
		Item = Form.Items.Insert("GoodsSetIndex", Type("FormField"), Form.Items.Goods, Form.Items.GoodsProducts);
		
		Item.DataPath        = "Object.Goods.SetIndex";
		Item.Type                = FormFieldType.PictureField;
		Item.ValuesPicture   = PictureLib.Sets;
		Item.HeaderPicture      = PictureLib.Set;
		Item.TitleLocation = FormItemTitleLocation.None;
		
		Item = Form.Items.Insert("ProductsGroupSets", Type("FormGroup"), Form.Items.Goods, Form.Items.GoodsProducts);
		Item.Title        = NStr("vi = 'Tập hợp';
								|ru = 'Наборы';
								|en = 'Sets'; fa = 'مجموعه‌ها';
								|it = 'Set';
								|pl = 'Sets';
								|tr = 'Kümeler'");
		Item.Group      = ColumnsGroup.InCell;
		Item.ShowInHeader = True;
		Item.Visible        = False;
		
		Item = Form.Items.Insert("GoodsProductsInSet", Type("FormField"), Form.Items.ProductsGroupSets);
		Item.DataPath = "Object.Goods.ProductsInSet";
		Item.ShowInHeader = False;
		
		Item = Form.Items.Insert("GoodsItemVariantOfSet", Type("FormField"), Form.Items.ProductsGroupSets);
		Item.DataPath = "Object.Goods.ItemVariantOfSet";
		Item.ShowInHeader = False;
		
		FormCommand = Form.Commands.Add("SetComposition");
		FormCommand.Title                 = NStr("vi = 'Đặt thành phần';
												|ru = 'Состав набора';
												|en = 'Set content'; fa = 'محتوای مجموعه';
												|it = 'Composizione del set';
												|pl = 'Skład zestawu';
												|tr = 'Set kapsamı'");
		FormCommand.Action                  = "Attachable_OverriddenCommand";
		FormCommand.Picture                  = PictureLib.Set;
		FormCommand.Representation               = ButtonRepresentation.Picture;
		FormCommand.ModifiesStoredData = True;
		
		Item             = Form.Items.Insert("SetComposition", Type("FormButton"), Form.Items.GroupCommandBarGoodsDeliveryTerms, Form.Items.GoodsSearchByBarcode);
		Item.Type         = FormButtonType.CommandBarButton;
		Item.Width      = 3;
		Item.CommandName  = "SetComposition";
		
		FormCommand = Form.Commands.Add("ShowSets");
		FormCommand.Title   = NStr("vi = 'Hiển thị bộ';
									|ru = 'Показать наборы';
									|en = 'Show sets'; fa = 'Show sets';
									|it = 'Mostra set';
									|pl = 'Pokaż zestawy';
									|tr = 'Kümeleri göster'");
		FormCommand.Action    = "Attachable_OverriddenCommand";
		FormCommand.Representation = ButtonRepresentation.Text;
		
		Item                       = Form.Items.Add("ShowSets", Type("FormButton"), Form.Items.CommandBarGoods);
		Item.Type                   = FormButtonType.UsualButton;
		Item.OnlyInAllActions = True;
		Item.CommandName            = "ShowSets";
	
	EndIf;
	
#EndRegion
	
#EndRegion
	
#Region Localization
	
	// Hiding elements for VAT accounting.
	UseVATAccounting = GetFunctionalOption("UseVATAccounting");
	
	If Not UseVATAccounting Then
		
		ItemArray = New Array;
		ItemArray.Add("GoodsVATRate");
		ItemArray.Add("GoodsVATAmount");
		ItemArray.Add("GoodsAmountIncludingVAT");
		ItemArray.Add("Taxation");
		ItemArray.Add("PriceIncludesVAT");
		ItemArray.Add("VATPageGroup");
		ItemArray.Add("TotalSNDSPage");
		
		For Each CollectionItem In ItemArray Do
			CommonClientServer.SetFormItemProperty(Form.Items,
				CollectionItem, "Visible", UseVATAccounting);
		EndDo;
		
	EndIf;
	
#EndRegion
	
	UpdateDependentDetailsOfProductItem(Form);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("BankingDetailsNamePartner",             "Client");
	AdditionalParameters.Insert("DoNotOutputMessagesByConvention", True);
	
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Form.Items.ShowMessages,,AdditionalParameters);
	
	If Not GetFunctionalOption("UseSalesCommission") Then
		
		ListItem = Form.Items.Operation.ChoiceList.FindByValue(Enums.KindsOfCommercialProposalProcedures.ConsignmentProcurement);
			
		If ListItem <> Undefined Then
			Form.Items.Operation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	Form.Items.GoodsVATRate.TypeRestriction = New TypeDescription("CatalogRef.VATRates");
	
	Form.Items.CreateBasedOnSubmenu.Picture = PictureLib.FillFromTemplate;
	
	If GetFunctionalOption("UsePartnersAndCounterparties") Then
		Form.Items.Counterparty.AutoMarkIncomplete = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(Form, Cancel, StandardProcessing);
	
EndProcedure

Procedure CommercialOfferToClientWhenReadingOnServer(Form, CurrentObject)
	
	CommercialOfferToClientWhenCreatingReadingOnServer(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenCreatingReadingOnServer(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	
	CurrentDate = CurrentSessionDate();
	
	CommercialOfferToClientToCreateAdditionalDetailsOfForm(Form);
	CommercialProposalsDocumentsClientServerTM.GenerateStatePresentationByStatus(Form, Form.Object.Status, CurrentDate);
	FillInTemporaryQuantityOfGoodsTabularPart(Form);
	
	Form.DocumentCurrency = Object.Currency;
	Form.ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	Form.UsePaymentSchedules        = GetFunctionalOption("UsePaymentSchedules");
	
	Items.FillInPaymentTerms.Visible = Form.ToUseTermsOfSales 
	                                            Or Form.UsePaymentSchedules;
	
	DefineDefaultPriceType(Form);
	
	If GetFunctionalOption("UseSets") Then
		SetsServer.FillInServiceDetails(Form);
	EndIf;
	
	FillParameters = CommercialOfferToClientParametersForFillingInVATTaxationSales(Object);
	VATTaxation = Form.VATTaxation;
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters, Form.VATAccountingCachedParameterValues);
	
	Taxation = CommercialProposalsDocumentsClientServerTM.TaxationOfCommercialProposalsForVATTaxation(VATTaxation);
	If Taxation <> Object.Taxation Then
		Object.Taxation = Taxation;
		CommercialOfferToClientInCaseOfChangesInVATTaxation(Form);
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientAfterRecordingOnServer(Form, CurrentObject)

	UpdateDependentDetailsOfProductItem(Form);
	FillInTemporaryQuantityOfGoodsTabularPart(Form);
	
	CurrentDate = CurrentSessionDate();
	If Form.Object.Goods.Count() > 0
		And CommonClientServer.HasAttributeOrObjectProperty(Form.Object.Goods[0], "SetIndex") Then
		SetsServer.FillInServiceDetails(Form);
	EndIf;
	CommercialProposalsDocumentsClientServerTM.GenerateStatePresentationByStatus(Form, Form.Object.Status, CurrentDate);

EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenSettingConditionalAppearance
//
// Parameters:
//  Form - ClientApplicationForm - the form for which the conditional design is defined.
//
Procedure CommercialOfferToClientWhenInstallingConditionalAppearance(Form)
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items           = Form.Items; // FormItems
	
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(Form);
	SetsServer.SetConditionalAppearance(Form, "Goods");
	
#Region Price
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ProductsPriceField = Items.GoodsPrice; // FormField
	ItemField.Field = New DataCompositionField(ProductsPriceField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
#EndRegion

#Region Sum

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ProductsAmountField = Items.GoodsPrice; // FormField
	ItemField.Field = New DataCompositionField(ProductsAmountField.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseDiscountAdjustmentsInSales");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.KindsOfCommercialProposalProcedures.ConsignmentProcurement;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
#EndRegion

EndProcedure

Procedure CommercialOfferToClientFillingProcessing(Object, FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		FillInCommercialOfferToClientOnBasisOfTransactionWithClient(Object, FillingData);
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef.CommercialProposalForCustomer") Then
		FillInCommercialOfferToClientOnBasisOfCommercialOfferToClient(Object, FillingData);
	EndIf;
	
	CommercialProposalsDocumentsLocalization.CommercialOfferToClientFillingProcessing(Object, FillingData, FillingText, StandardProcessing);
	
	If Not ValueIsFilled(Object.Status) Then
		Object.Status = Enums.StatusesOfCommercialProposalsForCustomers.Draft;
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		Object.Taxation = True;
	EndIf;
	
	FillParameters = ParametersForFillingInSalesVATTaxation(Object);
	VATTaxtion   = CommercialProposalsDocumentsClientServerTM.TaxationOfVATOnTaxationOfCommercialOffers(Object.Taxation);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxtion,
	                                             FillParameters);
	Object.Taxation = CommercialProposalsDocumentsClientServerTM.TaxationOfCommercialProposalsForVATTaxation(VATTaxtion);
	
EndProcedure

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.CommercialProposalForCustomer - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date        = Object.Date;
	FillParameters.ThisIsOrder    = True;
	
	If Object.BusinessOperation = Enums.KindsOfCommercialProposalProcedures.PurchaseFromSupplier Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf Object.BusinessOperation = Enums.KindsOfCommercialProposalProcedures.ConsignmentProcurement Then
		
		FillParameters.TransferToCommissionAgent = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

Procedure CommercialOfferToClientInCaseOfChangesInVATTaxation(Form)

	Object = Form.Object;
	
	If Object.Taxation Then
		FillParameters = CommercialOfferToClientParametersForFillingInVATTaxationSales(Object);
		OrganizationAccountingParameters = VATAccountingERP.AccountingParametersForOrganization(FillParameters.Organization,FillParameters.Date);
		Form.VATTaxation = OrganizationAccountingParameters.BasicTaxationVATSales;
	Else
		Form.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	StructureOfFillingInVATRate.Insert("VATTaxation", Form.VATTaxation);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate",              StructureOfFillingInVATRate);
	
	ParametersFillInVATRate =  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.VATTaxation = Form.VATTaxation;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmount",             StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",            StructureOfRecalculationOfAmount);

	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingPriceIncludesVAT(Form, Taxation)

	Object = Form.Object;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	DefineDefaultPriceType(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingCurrency(Form)

	Object = Form.Object;
	
	NewCurrency                 = Object.Currency;
	OldCurrency                = Form.DocumentCurrency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, Object.Date, LocalAccountingCurrency);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency, Object.Date, LocalAccountingCurrency);
	
	PriceManagementSystem.ConvertTabularAmountsToCurrency(
		Object.Goods,
		Object.PriceIncludesVAT,
		OldCurrency,
		NewCurrency,
		StructureOfOldCurrencyRates,
		StructureOfNewCurrencyRates,
		True,
		True,
		"Count");
		
	Form.DocumentCurrency = Object.Currency;
	
EndProcedure

Procedure CommercialOfferToClientWhenOrganizationChanges(Form)

	CommercialOfferToClientToFillInVATTaxationOfSale(Form);

	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Form.Object.Organization);
	If Not ValueIsFilled(Form.Object.Currency) Then
		Form.Object.Currency = CurrencyOfComplianceAccounting;
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientInCaseOfChangeOfBusinessOperation(Form)
	
	CommercialOfferToClientToFillInVATTaxationOfSale(Form);
	
EndProcedure

Procedure DefineDefaultPriceType(Form)
	
	Object = Form.Object;
	
	PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
	PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
	PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
	PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
	
	Form.DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	
EndProcedure

Procedure UpdateDependentDetailsOfProductItem(Form)
	
	Object = Form.Object;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
EndProcedure

Procedure FillInTemporaryQuantityOfGoodsTabularPart(Form)
	
	Object = Form.Object;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	For Each CurrentRow In Object.Goods Do
		
		CurRowStructure = GetCurLine(CurrentRow, StructureOfActions);
		CurRowStructure.Insert("Package", CurrentRow.UnitOfMeasure);
		CurRowStructure.Insert("NumberOfPackages", CurrentRow.Count);
		CurRowStructure.Count = CurrentRow.QuantityIsTemporary;
		
		BatchProcessingOfTablePartServer.ProcessTSString(
			CurRowStructure,
			StructureOfActions,
			CachedValues);
		FillPropertyValues(CurrentRow, CurRowStructure);
	
		CurrentRow.QuantityIsTemporary = CurRowStructure.Count;
		CurrentRow.Count = CurRowStructure.NumberOfPackages;
		
	EndDo;
	
EndProcedure

Function GetCurLine(CurrentRow, StructureOfActions)
	Var StructureOfActionParameters;

	StructureOfTSFields = New Structure;

	If StructureOfActions.Property("RecalculateNumberOfUnits") Then
		StructureOfTSFields.Insert("Products");
		StructureOfTSFields.Insert("Package");
		StructureOfTSFields.Insert("NumberOfPackages", 0);
		StructureOfTSFields.Insert("Count", 0);
		StructureOfTSFields.Insert("QuantityIsTemporary", 0);
	EndIf;
	
	If StructureOfActions.Property("RecalculateNumberOfUnits", StructureOfActionParameters)
	   And StructureOfActionParameters <> Undefined 
	   And StructureOfActionParameters.Property("MustBeRoundOff")
	   And CurrentRow.Property("MustBeRoundOff") Then
		StructureOfTSFields.Insert("MustBeRoundOff");	
	EndIf;
	
	FillPropertyValues(StructureOfTSFields, CurrentRow);
	
	Return StructureOfTSFields;
	
EndFunction

Procedure CommercialOfferToClientToFillInVATTaxationOfSale(Form)
	
	Object = Form.Object;
	
	FillParameters = CommercialOfferToClientParametersForFillingInVATTaxationSales(Object);
	VATTaxation = CommercialProposalsDocumentsClientServerTM.TaxationOfVATOnTaxationOfCommercialOffers(Object.Taxation);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters, Form.VATAccountingCachedParameterValues);
	
	Taxation = CommercialProposalsDocumentsClientServerTM.TaxationOfCommercialProposalsForVATTaxation(VATTaxation);
	If Taxation <> Object.Taxation Then
		Object.Taxation = Taxation;
		CommercialOfferToClientInCaseOfChangesInVATTaxation(Form);
	EndIf;
	
	If Taxation Then
		OrganizationAccountingParameters = VATAccountingERP.AccountingParametersForOrganization(FillParameters.Organization,FillParameters.Date);
		Form.VATTaxation = OrganizationAccountingParameters.BasicTaxationVATSales;
	Else
		Form.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	EndIf;
	
EndProcedure

Function CommercialOfferToClientParametersForFillingInVATTaxationSales(Object)
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date        = Object.Date;
	FillParameters.ThisIsOrder    = True;
	
	If Object.BusinessOperation = Enums.KindsOfCommercialProposalProcedures.PurchaseFromSupplier Then
		
		FillParameters.GoodsSales    = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf Object.BusinessOperation = Enums.KindsOfCommercialProposalProcedures.ConsignmentProcurement Then
		
		FillParameters.TransferToCommissionAgent = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

Procedure CommercialOfferToClientToCreateAdditionalDetailsOfForm(Form)
	
	If Not Form.AdditionalAttributesCreated Then
		
		UseSets = GetFunctionalOption("UseSets");
		
		AttributesToBeAdded = New Array;
		AttributesToBeAdded.Add(New FormAttribute("ItemsType",
		                                                  New TypeDescription("EnumRef.ItemsTypes"),
		                                                  "Object.Goods"));
		AttributesToBeAdded.Add(New FormAttribute("DefaultPriceType",
		                                                  New TypeDescription("CatalogRef.TypesOfPrices")));
		AttributesToBeAdded.Add(New FormAttribute("DocumentCurrency",
		                                                  New TypeDescription("CatalogRef.Currencies")));
		AttributesToBeAdded.Add(New FormAttribute("VATAccountingCachedParameterValues",
		                                                  New TypeDescription()));
		AttributesToBeAdded.Add(New FormAttribute("SupportedPeripheralTypes",
		                                                  New TypeDescription("String")));
		AttributesToBeAdded.Add(New FormAttribute("UsePeripherals",
		                                                  New TypeDescription("Boolean")));
		AttributesToBeAdded.Add(New FormAttribute("AddressOfAppliedDiscountsInTheTemporaryStorage",
		                                                  New TypeDescription("String")));
		AttributesToBeAdded.Add(New FormAttribute("ManagedDiscounts",
		                                                  New TypeDescription("ValueList")));
		AttributesToBeAdded.Add(New FormAttribute("ToUseTermsOfSales",
		                                                  New TypeDescription("Boolean")));
		AttributesToBeAdded.Add(New FormAttribute("UsePaymentSchedules",
		                                                  New TypeDescription("Boolean")));
		AttributesToBeAdded.Add(New FormAttribute("UsePriceManagementSystem25",
		                                                  New TypeDescription("Boolean")));
		
		If UseSets Then
			AttributesToBeAdded.Add(New FormAttribute("SetIndex",
			                                                  Common.TypeDescriptionNumber(10),
			                                                  "Object.Goods"));
		EndIf;
		
		AttributesToBeAdded.Add(New FormAttribute("QuantityIsTemporary",
		                                                  New TypeDescription("Number"),
		                                                  "Object.Goods"));

		Form.ChangeAttributes(AttributesToBeAdded);
		
		Form.AdditionalAttributesCreated = True;
	
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientProcessingResultOfSelectionOfProducts(Form, ValueSelected, AdditionalParameters, ProcessingResult)
	
	OperationType = "SelectionOfTheNomenclature";
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		
		If ValueSelected.Property("EditSet") Then
		
			OperationType = "EditSet";
			
		ElsIf ValueSelected.Property("EditSet") Then 
			
			OperationType = "EditSet";
			
		EndIf;
			
	ElsIf TypeOf(ValueSelected) = Type("String")
		And ValueSelected = "DeleteEntireSet" Then
		
		OperationType = "DeletingSet";
		
	EndIf;
	
	If OperationType = "SelectionOfTheNomenclature" Then
		
		Object = Form.Object; // DocumentObject.CommercialProposalForCustomer
		
		TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		StructureFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		StructureFillInVATRate.VATTaxation = Form.VATTaxation;
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInProductTypeAttribute_",             New Structure("Products", "ItemsType"));
		StructureOfActions.Insert("FillInVATRate",                          StructureFillInVATRate);
			
		ParametersFillInVATRate =  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
		ParametersFillInVATRate.VATTaxation = Form.VATTaxation;
		StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);

		StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount",                            "Count");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",         New Structure("Clear, QuantityName", False, "Count"));
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear, QuantityName", True, "Count"));
		
		RowsToProcess = New Array();
		
		For Each RowOfProduct In TableOfGoods Do
			
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(
				CurrentRow,
				RowOfProduct,
				" ProductsInSet, ItemVariantOfSet, Products, Characteristic, PriceKind, Price, PercentRateOfManualDiscount");
				
			If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "SetIndex") Then
				//@skip-warning
				CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
			EndIf;
				
			CurrentRow.UnitOfMeasure    = RowOfProduct.Package;
			//@skip-warning
			CurrentRow.QuantityIsTemporary = RowOfProduct.Count;
			CurrentRow.Count          = RowOfProduct.NumberOfPackages;
			
			RowsToProcess.Add(CurrentRow);
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			CachedValues);
		
		StructureCharacteristicsOfProducts = New Structure;
		StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",New Structure("Products", "ItemVariantsAreUsed"));
		
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
		
	ElsIf OperationType = "DeletingSet" Then
		
		SetsServer.WhenRemovingComponents(Form, "Goods", AdditionalParameters);
		
	ElsIf OperationType = "EditSet" Then
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		StructureOfActionsWithAddedStrings = New Structure;
		StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
		DataParameters = New Structure;
		DataParameters.Insert("Data", GetFromTempStorage(ValueSelected.AddressInTempStorage));
		DataParameters.Insert("StructureOfActionsWithModifiedStrings", New Structure);
		DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
		DataParameters.Insert("DialColumns", DialColumns(Form));
		
		MapColumnNames = MatchingColumnNamesForSet();
		
		DataParameters.Insert("MapColumnNames", MapColumnNames);
		
		SetsServer.AtEndOfEditingSet(Form, "Goods", DataParameters);
		
	ElsIf OperationType = "EditSet" Then
		
		ProcessingResult = ParametersForOpeningSetComposition(Form);
		
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientToDownloadDataReceivedFromExternalFile(Form, ValueSelected)
	
	Object = Form.Object; // DocumentObject.CommercialProposalForCustomer
	
	StructureOfActions = New Structure;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount",                            "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",         New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear, QuantityName", True, "Count"));
	
	ItemsFromStorage = GetFromTempStorage(ValueSelected);
	
	RowsToProcess = New Array();
	
	For Each RowOfGoods In ItemsFromStorage Do
		
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		StringTSGoods.UnitOfMeasure     = RowOfGoods.Package;
		//@skip-warning
		StringTSGoods.QuantityIsTemporary = RowOfGoods.Count;
		StringTSGoods.Count          = RowOfGoods.NumberOfPackages;
		
		RowsToProcess.Add(StringTSGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
EndProcedure

Procedure CommercialOfferToClientToProcessBarcodeInput(Form, BarcodeData_1, ProcessingResult)
	
	Object = Form.Object;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	StructureFillInVATRate.VATTaxation = Form.VATTaxation;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate",                         StructureFillInVATRate);
		
	ParametersFillInVATRate =  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.VATTaxation = Form.VATTaxation;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	
	StructureOfActionsWithAddedStrings.Insert("FillInSalePrice",                       BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActionsWithAddedStrings.Insert("RecalculateVATAmount",                        StructureOfRecalculationOfAmount);
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmountWithVAT",                       StructureOfRecalculationOfAmount);
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmount",                           "Count");
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount",        New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount",New Structure("Clear, QuantityName", True, "Count"));
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateVATAmount",                        StructureOfRecalculationOfAmount);
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmountWithVAT",                       StructureOfRecalculationOfAmount);
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmount",                           "Count");
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount",        New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount",New Structure("Clear, QuantityName", True, "Count"));
	
	StructureOfActions = BarcodingOfItemsClientServer.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_1;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.ColumnNamePackaging                     = "UnitOfMeasure";
	StructureOfActions.ColumnNameQuantity                   = "Count";
	
	If Object.BusinessOperation = Enums.KindsOfCommercialProposalProcedures.PurchaseFromSupplier Then
		StructureOfActions.OnlyGoodsAndWork = True;
	Else
		StructureOfActions.GoodsOnly = True;
	EndIf;
	
	CachedValues = Undefined;
	BarcodingOfItemsServer.ProcessBarcodes(Form, Object, StructureOfActions, CachedValues);
	
	ProcessingResult = StructureOfActions;
	ProcessingResult.Insert("CachedValues", CachedValues);
	
EndProcedure

Procedure CommercialOfferToClientFillInPricesByTypeOfPrices(Form, PriceKind, AdditionalParameters)
	
	Object = Form.Object;
	SelectedRows = AdditionalParameters.SelectedRows;
	
	RowsArray = New Array;
	For Each String In SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",                    "Count");
	StructureOfActions.Insert("RecalculateVATAmount",                 StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount",        "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	FillParameters = New Structure();
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("PriceKind",            PriceKind);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("CalculateSets", False);
	FillParameters.Insert("PopulationFields",     "Price, PriceKind");
	FillParameters.Insert("ColumnNamePackaging", "UnitOfMeasure");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
		
	If PricesCalculated Then
		Object.DiscountsAreCalculated = False;
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientToFillInPricesAccordingToSalesCondition(Form, SalesCondition, AdditionalParameters)

	Object = Form.Object;
	SelectedRows = AdditionalParameters.SelectedRows;
	
	RowsArray = New Array;
	For Each String In SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",                    "Count");
	StructureOfActions.Insert("RecalculateVATAmount",                 StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount",        "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	VATTaxation = CommercialProposalsDocumentsClientServerTM.TaxationOfCommercialProposalsForVATTaxation(Object.Taxation);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("Terms",         SalesCondition);
	FillParameters.Insert("Organization",        Object.Organization);
	FillParameters.Insert("CalculateSets", False);
	FillParameters.Insert("VATTaxation", VATTaxation);
	FillParameters.Insert("ColumnNamePackaging", "UnitOfMeasure");
	FillParameters.Insert("PopulationFields",     "Price, PriceKind, DeliveryPeriodDays");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, 
		FillParameters,
		StructureOfActions);
	
	If PricesCalculated Then
		Object.DiscountsAreCalculated = False;
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientWhenExecutingOverridableCommand(Form, CommandName, ProcessingResult)
	
	If CommandName = "ShowMessages" Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("BankingDetailsNamePartner", "Client");
		ProcessingResult = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Form.Object, AdditionalParameters);
		
	ElsIf CommandName = "SetComposition" Then
		
		ProcessingResult = ParametersForOpeningSetComposition(Form);
		
	EndIf;
	
EndProcedure

// Returns parameters for opening the set composition.
// 
// Parameters:
// 	Form - ClientApplicationForm
// Returns:
// 	Structure, Undefined - LongDesc:
// * DoNotPickReusablePackage - Boolean
// * HideCommandRemainingQuantityInWarehouses - Boolean
// * VATTaxation - EnumRef.VATTaxationTypes
// * AddressInTempStorage - String
//
Function ParametersForOpeningSetComposition(Form)
	
	Items = Form.Items;
	Object   = Form.Object;
	
	Goods = Items.Goods; // FormTable
	RowSelected = Goods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return Undefined;
	EndIf;
	
	CurrentRow = Object.Goods.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		Return Undefined;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DialColumns", DialColumns(Form));
	KitParameters.Insert("MatchingColumnNamesForSet", MatchingColumnNamesForSet());
	
	SetAddressInTemporaryStorage = SetsServer.SetAddressInTemporaryStorage(Form, KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Form.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	OpeningParameters.Insert("DoNotPickReusablePackage", True);
	
	Return OpeningParameters;
	
EndFunction

Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	Columns.Add("Package");
	
	If Form.Object.BusinessOperation = PredefinedValue("Enum.KindsOfCommercialProposalProcedures.PurchaseFromSupplier") Then
		If Form.AccountingSettings.ManualDiscountsAreUsedInSales Then
			Columns.Add("PercentRateOfManualDiscount");
			Columns.Add("ManualDiscount");
		EndIf;
		If Form.AccountingSettings.AutomaticDiscountsInSalesAreUsed Then
			Columns.Add("PercentRateOfAutomaticDiscountMarkup");
			Columns.Add("DiscountMarkupAmount");
		EndIf;
	EndIf;
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");
	
	Return Columns;
	
EndFunction

Function MatchingColumnNamesForSet()
	
	ColumnsNames = New Map;
	ColumnsNames.Insert("Package", "UnitOfMeasure");
	ColumnsNames.Insert("NumberOfPackages", "Count");
	
	Return ColumnsNames;
	
EndFunction

Procedure CommercialOfferToClientWhenAddingReportCommands(ReportsCommands, Parameters)
	
	Reports.DiscountsAppliedInDocument.AddReportCommand(ReportsCommands);
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		Reports.SalesProfitabilityAssessment2_5.AddReportCommand(ReportsCommands);
	Else
		Reports.SalesProfitabilityAssessment.AddReportCommand(ReportsCommands);
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientToCalculateDiscounts(Form, ProcessingResult)
	
	CalculationParameters = DiscountsMarkupsFillingServer.NewParametersCalculate();
	CalculationParameters.ApplyToObject					 = True;
	CalculationParameters.OnlyPreliminaryCalculation		 = False;
	CalculationParameters.RestoreManagedDiscounts	 = True;
	CalculationParameters.ManagedDiscounts					 = Form.ManagedDiscounts;
	CalculationParameters.ColumnNamePackaging					 = "UnitOfMeasure";
	CalculationParameters.ColumnNameNumberOfPackages		 = "Count";
	
	ProcessingResult = ResultOfDiscountCalculation(Form, CalculationParameters);
	
EndProcedure

Procedure CommercialOfferToClientToPrepareOpeningOfInformationAboutDiscountsOnServer(Form, ProcessingResult)
	
	Object = Form.Object;
	
	If Not Object.DiscountsAreCalculated Then
		
		CalculationParameters = DiscountsMarkupsFillingServer.NewParametersCalculate();
		CalculationParameters.ApplyToObject					 = True;
		CalculationParameters.OnlyPreliminaryCalculation		 = False;
		CalculationParameters.RestoreManagedDiscounts	 = True;
		CalculationParameters.ManagedDiscounts					 = Form.ManagedDiscounts;
		CalculationParameters.ColumnNamePackaging					 = "UnitOfMeasure";
		CalculationParameters.ColumnNameNumberOfPackages		 = "Count";
		
		ProcessingResult = ResultOfDiscountCalculation(Form, CalculationParameters);
		
	EndIf;
	
	If Not ValueIsFilled(Form.AddressOfAppliedDiscountsInTheTemporaryStorage) Then
		CalculateDiscountsWithoutApplyingToObject(Form);
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientWhenCancelingManualDiscountsOnServer(Form, ProcessingResult)
	
	Object = Form.Object;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ColumnNameQuantity", "Count");
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Goods", True, True, False, False, AdditionalParameters);
	
EndProcedure

Procedure CommercialOfferToClientWhenAssigningManualDiscountOnServer(Form, ProcessingResult)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.OnlyForSelectedLines = True;
	ParametersStructure.TableName = "Goods";
	ProcessingResult = DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		Form, Form.UUID, ParametersStructure);
	
EndProcedure

Procedure CommercialOfferToClientAfterAssigningManualDiscountOnServer(Form, SelectedRows, ProcessingResult, AdditionalParameters)
	
	Object = Form.Object;
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = True;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AdditionalParameters.AddressInTempStorage;
	DiscountParameters.ColumnNameQuantity			 = "Count";
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Goods", ProcessingResult, DiscountParameters);
	
EndProcedure

Procedure CommercialOfferToClientAfterAssigningAutomaticDiscountOnServer(Form, Result, AdditionalParameters)
	
	CalculationParameters = DiscountsMarkupsFillingServer.NewParametersCalculate();
	CalculationParameters.ApplyToObject					 = True;
	CalculationParameters.OnlyPreliminaryCalculation		 = False;
	CalculationParameters.RestoreManagedDiscounts	 = False;
	CalculationParameters.ManagedDiscounts					 = Form.ManagedDiscounts;
	CalculationParameters.ColumnNamePackaging					 = "UnitOfMeasure";
	CalculationParameters.ColumnNameNumberOfPackages		 = "Count";
	
	Result = ResultOfDiscountCalculation(Form, CalculationParameters);
	
EndProcedure

Procedure CommercialOfferToClientWhenAssigningAutomaticDiscountsOnServer(Form, Result)
	
	Object = Form.Object;
	
	CalculationParameters = DiscountsMarkupsFillingServer.NewParametersCalculate();
	CalculationParameters.ApplyToObject					 = False;
	CalculationParameters.OnlyPreliminaryCalculation		 = True;
	CalculationParameters.RestoreManagedDiscounts	 = True;
	CalculationParameters.ManagedDiscounts					 = Form.ManagedDiscounts;
	CalculationParameters.ColumnNamePackaging					 = "UnitOfMeasure";
	CalculationParameters.ColumnNameNumberOfPackages		 = "Count";
	CalculatedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, CalculationParameters);
	Result = PutToTempStorage(CalculatedDiscounts, Form.UUID);
	
EndProcedure

// Parameters:
// 	PrintObjectDataStructure - Structure:
//   * PrimaryRecipient - String 
//   * ArrayOfRecipientDetails - Array
//
Procedure CommercialOfferToClientFillInStructureDataOfRecipientOfPrintedForm(PrintObjectDataStructure)
	
	PrintObjectDataStructure.PrimaryRecipient = "Client";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Client");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");

EndProcedure

Procedure CommercialOfferToClientProcessingFillCheckOnServer(DocumentObject, Cancel, CheckedAttributes, NotCheckedAttributeArray)
	
	AttributesNotToCheck = NotCheckedAttributeArray; // Array of String
	AttributesNotToCheck.Add("Goods.UnitOfMeasure");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(DocumentObject, AttributesNotToCheck, Cancel);
	
	If GetFunctionalOption("UsePartnersAndCounterparties") Then
		AttributesNotToCheck.Add("Counterparty");
	EndIf;
	
EndProcedure

Function ResultOfDiscountCalculation(Form, CalculationParameters, TakeFromTemporaryStorage = False)
	
	Object   = Form.Object;
	Items = Form.Items;
	
	If TakeFromTemporaryStorage Then
		AppliedDiscounts = GetFromTempStorage(Form.AddressOfAppliedDiscountsInTheTemporaryStorage);
		DiscountsMarkupsFillingServer.ApplyCalculationResult(Object, AppliedDiscounts);
	Else
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, CalculationParameters);
		Form.AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, Form.UUID);
	EndIf;
	
	Object.DiscountsAreCalculated = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("BankingDetailsNamePartner", "Client");
	AdditionalParameters.Insert("DoNotOutputMessagesByConvention", True);
	
	ProcessingResult = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object, AdditionalParameters);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages,,AdditionalParameters);
	
	Return ProcessingResult;
	
EndFunction

Procedure CalculateDiscountsWithoutApplyingToObject(Form)
	
	Object = Form.Object;
	
	CalculationParameters = DiscountsMarkupsFillingServer.NewParametersCalculate();
	CalculationParameters.ApplyToObject					 = False;
	CalculationParameters.OnlyPreliminaryCalculation		 = False;
	CalculationParameters.RestoreManagedDiscounts	 = True;
	CalculationParameters.ManagedDiscounts					 = Form.ManagedDiscounts;
	CalculationParameters.ColumnNamePackaging					 = "UnitOfMeasure";
	CalculationParameters.ColumnNameNumberOfPackages		 = "Count";
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, CalculationParameters);
	
	PutToTempStorage(AppliedDiscounts, Form.UUID);
	
EndProcedure

Procedure EventProcessingWhenRecordingCommercialOfferToClient(DocumentObject, Cancel)
	
	State = StateOfOffer(DocumentObject);
	
	InformationRegisters.StatesOfCommercialProposalsToCustomers.RecordState(DocumentObject.Ref, State);
	
EndProcedure

Procedure FillInCommercialOfferToClientOnBasisOfTransactionWithClient(Object, FillingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	SalesOpportunitiesToCustomer.Ref                                AS SalesOpportunity,
	|	SalesOpportunitiesToCustomer.Partner                               AS Client,
	|	SalesOpportunitiesToCustomer.CustomerTermsOfSales                   AS Terms,
	|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson AS ContactPerson
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS SalesOpportunitiesToCustomerPartnersAndContactPersons
	|		ON SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref = SalesOpportunitiesToCustomer.Ref
	|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner = SalesOpportunitiesToCustomer.Partner
	|				AND SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
	|WHERE
	|	SalesOpportunitiesToCustomer.Ref = &Basis";
	
	Query.SetParameter("Basis", FillingData);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfSaleTransaction(Selection.Client);
	FillPropertyValues(Object, Selection);
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Client,    Object.Counterparty);
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Client, Object.ContactPerson);
	
	If ValueIsFilled(Selection.Terms) Then
		Terms = Common.ObjectAttributesValues(Selection.Terms, "Organization, Currency, PriceIncludesVAT", True);
		
		Object.Organization        = Terms.Organization;
		Object.Currency             = Terms.Currency;
		Object.PriceIncludesVAT    = Terms.PriceIncludesVAT;
		Object.PaymentTermsText = CommercialProposalsDocumentsTMServerCall.PaymentTermsByText(Selection.Terms);
	EndIf;
	
EndProcedure

Procedure FillInCommercialOfferToClientOnBasisOfCommercialOfferToClient(Object, FillingData)

	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	CommercialProposalForCustomer.Organization                         AS Organization,
	|	CommercialProposalForCustomer.Client                              AS Client,
	|	CommercialProposalForCustomer.SalesOpportunity                              AS SalesOpportunity,
	|	CommercialProposalForCustomer.Counterparty                          AS Counterparty,
	|	CommercialProposalForCustomer.ContactPerson                      AS ContactPerson,
	|	CommercialProposalForCustomer.BusinessOperation               AS BusinessOperation,
	|	CommercialProposalForCustomer.Currency                              AS Currency,
	|	CommercialProposalForCustomer.Taxation                     AS Taxation,
	|	CommercialProposalForCustomer.PriceIncludesVAT                     AS PriceIncludesVAT,
	|	CommercialProposalForCustomer.ValidityPeriod                        AS ValidityPeriod,
	|	CommercialProposalForCustomer.DeliveryTermsText                AS DeliveryTermsText,
	|	CommercialProposalForCustomer.PaymentTermsText                  AS PaymentTermsText,
	|	CommercialProposalForCustomer.OtherAdditionalInformationText AS OtherAdditionalInformationText,
	|	CommercialProposalForCustomer.PartialSaleAllowed             AS PartialSaleAllowed,
	|	CommercialProposalForCustomer.Manager                            AS Manager,
	|	CommercialProposalForCustomer.OptionToSpecifyDeliveryTerm        AS OptionToSpecifyDeliveryTerm,
	|	CommercialProposalForCustomer.DocumentAmount                      AS DocumentAmount,
	|	CommercialProposalForCustomer.AdditionalInformationToCustomerHTML AS AdditionalInformationToCustomerHTML,
	|	CommercialProposalForCustomer.Comment                         AS Comment,
	|	CommercialProposalForCustomer.HashQueryAmount                     AS HashQueryAmount,
	|	CommercialProposalForCustomer.LoyaltyCard                     AS LoyaltyCard,
	|	CASE
	|		WHEN VALUETYPE(CommercialProposalForCustomer.DocumentBasis) = &TypeOfCommonGround
	|			THEN CommercialProposalForCustomer.DocumentBasis
	|		ELSE CommercialProposalForCustomer.Ref
	|	END                                                              AS DocumentBasis,
	|	CommercialProposalForCustomer.SKPIDInService            AS SKPIDInService,
	|	NOT CommercialProposalForCustomer.Posted                         AS ThereAreErrorsPosted
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|WHERE
	|	CommercialProposalForCustomer.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CommercialOfferToClientGoods.PriceKind                                   AS PriceKind,
	|	CommercialOfferToClientGoods.UnitOfMeasure                          AS UnitOfMeasure,
	|	CommercialOfferToClientGoods.QueryUnitOfMeasure                    AS QueryUnitOfMeasure,
	|	CommercialOfferToClientGoods.QueryQuantity                          AS QueryQuantity,
	|	CommercialOfferToClientGoods.QueryDeliveryPeriod                        AS QueryDeliveryPeriod,
	|	CommercialOfferToClientGoods.QueryPrice                                AS QueryPrice,
	|	CommercialOfferToClientGoods.IDForItemMapping AS IDForItemMapping,
	|	CommercialOfferToClientGoods.RowIDRequest                AS RowIDRequest,
	|	CommercialOfferToClientGoods.ConnectionKey                                 AS ConnectionKey,
	|	CommercialOfferToClientGoods.Count                                AS Count,
	|	CommercialOfferToClientGoods.InternalComment                     AS InternalComment,
	|	CommercialOfferToClientGoods.CommentForCustomer                  AS CommentForCustomer,
	|	CommercialOfferToClientGoods.Products                              AS Products,
	|	CommercialOfferToClientGoods.ProductsInIDService         AS ProductsInIDService,
	|	CommercialOfferToClientGoods.ProductsInSet                        AS ProductsInSet,
	|	CommercialOfferToClientGoods.CustomerProductsID       AS CustomerProductsID,
	|	CommercialOfferToClientGoods.CustomerProductsPresentation       AS CustomerProductsPresentation,
	|	CommercialOfferToClientGoods.LineNumber                               AS LineNumber,
	|	CommercialOfferToClientGoods.PercentRateOfAutomaticDiscountMarkup               AS PercentRateOfAutomaticDiscountMarkup,
	|	CommercialOfferToClientGoods.PercentRateOfManualDiscount                       AS PercentRateOfManualDiscount,
	|	CommercialOfferToClientGoods.DeliveryPeriodDays                              AS DeliveryPeriodDays,
	|	CommercialOfferToClientGoods.VATRate                                 AS VATRate,
	|	CommercialOfferToClientGoods.Sum                                     AS Sum,
	|	CommercialOfferToClientGoods.DiscountMarkupAmount                 AS DiscountMarkupAmount,
	|	CommercialOfferToClientGoods.VATAmount                                  AS VATAmount,
	|	CommercialOfferToClientGoods.ManualDiscount                         AS ManualDiscount,
	|	CommercialOfferToClientGoods.AmountIncludingVAT                                 AS AmountIncludingVAT,
	|	CommercialOfferToClientGoods.Characteristic                            AS Characteristic,
	|	CommercialOfferToClientGoods.CharacteristicInIDService       AS CharacteristicInIDService,
	|	CommercialOfferToClientGoods.ItemVariantOfSet                      AS ItemVariantOfSet,
	|	CommercialOfferToClientGoods.HashQueryRowAmount                     AS HashQueryRowAmount,
	|	CommercialOfferToClientGoods.Price AS Price
	|FROM
	|	Document.CommercialProposalForCustomer.Goods AS CommercialOfferToClientGoods
	|WHERE
	|	CommercialOfferToClientGoods.Ref = &DocumentBasis
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CommercialProposalForCustomerDiscountsMarkups.LineNumber    AS LineNumber,
	|	CommercialProposalForCustomerDiscountsMarkups.ConnectionKey      AS ConnectionKey,
	|	CommercialProposalForCustomerDiscountsMarkups.DiscountMarkup  AS DiscountMarkup,
	|	CommercialProposalForCustomerDiscountsMarkups.Sum          AS Sum,
	|	CommercialProposalForCustomerDiscountsMarkups.RemindLater AS RemindLater
	|FROM
	|	Document.CommercialProposalForCustomer.DiscountsMarkups AS CommercialProposalForCustomerDiscountsMarkups
	|WHERE
	|	CommercialProposalForCustomerDiscountsMarkups.Ref = &DocumentBasis
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("TypeOfCommonGround", 
		CommercialProposalsDocumentsLocalization.BaseTypeCommercialOfferToClientByDefault());
	
	Query.SetParameter("DocumentBasis", FillingData);
	
	QueryResult = Query.ExecuteBatch(); 
	
	HeaderSelection = QueryResult[0].Select();
	
	HeaderSelection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfCommercialProposalsForCustomers.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentBasis,
		,
		HeaderSelection.ThereAreErrorsPosted);
	
	FillPropertyValues(Object, HeaderSelection);
	
	SampleProducts_ = QueryResult[1].Select();
	While SampleProducts_.Next() Do
		NewLineProducts = Object.Goods.Add();
		FillPropertyValues(NewLineProducts, SampleProducts_);
	EndDo;
	
	DiscountSelection = QueryResult[2].Select();
	While DiscountSelection.Next() Do
		NewRowDiscount = Object.DiscountsMarkups.Add();
		FillPropertyValues(NewRowDiscount, DiscountSelection);
	EndDo;

EndProcedure

Function StateOfOffer(DocumentObject)
	
	State = Undefined;
	
	If DocumentObject.DeletionMark Then
		
		State = Undefined;
	
	ElsIf Not DocumentObject.Posted
		Or DocumentObject.Status = Enums.StatusesOfCommercialProposalsForCustomers.Draft Then
		
		State = Enums.StatesOfCommercialProposalsToCustomers.Prepared_;
		
	ElsIf DocumentObject.Status = Enums.StatusesOfCommercialProposalsForCustomers.NotApproved Then
		
		State = Enums.StatesOfCommercialProposalsToCustomers.PendingApproval;
		
	ElsIf DocumentObject.Status = Enums.StatusesOfCommercialProposalsForCustomers.Canceled Then
		
		State = Enums.StatesOfCommercialProposalsToCustomers.Canceled;
		
	Else
		
		State = Enums.StatesOfCommercialProposalsToCustomers.Valid;
		
	EndIf;
		
	Return State;
	
EndFunction

#EndRegion

#Region GeneralProceduresAndFunctions

Procedure AddUnitFormElement(Form) Export
	
	Var Item;
	
	Item     = Form.Items.Add("GoodsProductsUnitOfMeasure", Type("FormField"), Form.Items.GoodsPackagingUnitOfMeasure);
	Item.Type                       = FormFieldType.InputField;
	Item.OpenButton            = False;
	Item.ReadOnly            = True;
	Item.ShowInHeader          = False;
	Item.Width                    = 8;
	Item.DataPath               = "Object.Goods.Products.UnitOfMeasure";
	Item.AutoMarkIncomplete = False;
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Goods.UnitOfMeasure";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);

EndProcedure

#EndRegion

#Region GenerationCommands

// Defines a list of creation commands based on.
//
// Parameters:
//   ObjectName - String - name of the object to add commands to.
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(ObjectName, GenerationCommands, Parameters)
	
	If ObjectName = Metadata.Documents.CommercialProposalForCustomer.Name Then
		
		Documents.SalesOrder.AddGenerateCommand(GenerationCommands);
		Documents.CommercialProposalForCustomer.AddGenerateCommand(GenerationCommands);
		BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
		
	EndIf;
	
	CommercialProposalsDocumentsLocalization.AddGenerationCommands(ObjectName, GenerationCommands, Parameters)
	
EndProcedure

// Adds a command to create a document based on.
//
// Parameters:
//   ObjectName - String - the name of the metadata object.
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   ValueTableRow, Undefined - contains a description of the added command.
//
Function AddGenerateCommand(ObjectName, GenerationCommands)
	
	If ObjectName = Metadata.Documents.CommercialProposalForCustomer.Name Then
		
		If AccessRight("Insert", Metadata.Documents.CommercialProposalForCustomer) Then
			CreateBasedOnCommand = GenerationCommands.Add();
			CreateBasedOnCommand.Manager = Metadata.Documents.CommercialProposalForCustomer.FullName();
			CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CommercialProposalForCustomer);
			CreateBasedOnCommand.WriteMode = "Post";
			CreateBasedOnCommand.FunctionalOptions = "UseCommercialProposalsForCustomers";
			
			Return CreateBasedOnCommand;
			
		EndIf;
		
	EndIf;
	
	CommercialProposalsDocumentsLocalization.AddGenerateCommand(ObjectName, GenerationCommands);
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
