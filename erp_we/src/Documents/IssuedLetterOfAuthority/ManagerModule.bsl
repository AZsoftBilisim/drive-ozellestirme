#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	IssuedLetterOfAuthorityLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.IssuedLetterOfAuthority") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		Query.SetParameter("Ref", DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		IssuedLetterOfAuthorityLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	IssuedLetterOfAuthorityLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the "power of Attorney" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.IssuedLetterOfAuthority) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IssuedLetterOfAuthority.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IssuedLetterOfAuthority);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAuthorizationLettersForInventoryReceipt";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	IssuedLetterOfAuthorityLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Returns the validity period of the last power of attorney entered by the responsible person in the system.
//
// Returns:
//	Number - the validity period of the last power of attorney.
//
Function GetValidityPeriodOfLastPowerOfAttorney() Export
	
	Query = New Query("
		|SELECT ALLOWED TOP 1
		|	LetterOfAuthority.ValidityPeriod AS ValidityPeriod
		|FROM
		|	Document.IssuedLetterOfAuthority AS LetterOfAuthority
		|WHERE
		|	NOT LetterOfAuthority.DeletionMark
		|	AND LetterOfAuthority.EmployeeResponsible = &EmployeeResponsible
		|ORDER BY
		|	Date DESC
		|");
		
	Query.SetParameter("EmployeeResponsible", Users.CurrentUser());
		
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Undefined;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		Return Selection.ValidityPeriod;
	EndIf;
	
EndFunction

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfAuthorizationLetters[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	TRUE AS Posted, // For a power of attorney document, the <Conduct> property is set to <Prohibit>
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	FALSE AS Recording
	|FROM
	|	Document.IssuedLetterOfAuthority AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - String - Name of the new status for documents
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the power of attorney
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Person)
	|	AND ValueAllowed(Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		If Not AccessRight("Read", Metadata.InformationRegisters.StatesByEDIAccountingObjects) Then
			StandardProcessing = False;
			SelectedForm = "ListForm";
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

Function PowerOfAttorneyForOrders(ObjectsArray) Export
	
	PowerOfAttorneyForOrders = New Array;
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
	"SELECT
	|	LetterOfAuthority.Ref
	|FROM
	|	Document.IssuedLetterOfAuthority AS LetterOfAuthority
	|WHERE
	|	NOT LetterOfAuthority.DeletionMark
	|	AND LetterOfAuthority.DocumentBasis IN(&ObjectsArray)";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	PowerOfAttorneyForOrders = Query.Execute().Unload().UnloadColumn("Ref");
	
	SetPrivilegedMode(False);
	
	Return PowerOfAttorneyForOrders;
	
EndFunction

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	IssuedLetterOfAuthorityLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	IssuedLetterOfAuthorityLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters)
		
EndProcedure


Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	IssuedLetterOfAuthorityLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Counterparty";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	EndIf;
	
EndProcedure

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters: 
//     ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.IssuedLetterOfAuthority.Form.DocumentsListForm";
	UseOfPowersOfAttorney = GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt");
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.IssuedLetterOfAuthority))
		And (AccessRight("Insert", Metadata.Documents.IssuedLetterOfAuthority)
			Or AccessRight("Update", Metadata.Documents.IssuedLetterOfAuthority))
		And UseOfPowersOfAttorney;
	
	If Not Enabled Then
		Return;
	EndIf;
	
	AvailabilityOfOrdersGoods = UseOfPowersOfAttorney
		And AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
		And AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
		
	AvailabilityOfDSOrders = UseOfPowersOfAttorney
		And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting)
		And AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting);
		
	// Documents.
	ReadOrderToSupplier = AccessRight("Read", Metadata.Documents.PurchaseOrder)
		And AccessRight("View", Metadata.Documents.PurchaseOrder);
	ReadingCustomerOrder = AccessRight("Read", Metadata.Documents.SalesOrder)
		And AccessRight("View", Metadata.Documents.SalesOrder);
	ReadRequestForReturnOfGoodsFromCustomer = AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer)
		And AccessRight("View", Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	ReadingActOfCompletedWorks = AccessRight("Read", Metadata.Documents.CustomerInvoiceServices)
		And AccessRight("View", Metadata.Documents.CustomerInvoiceServices);
	NetSalesOfServicesOtherAssets = AccessRight("Read", Metadata.Documents.CustomerInvoiceServicesAndAssets)
		And AccessRight("View", Metadata.Documents.CustomerInvoiceServicesAndAssets);
	ReadingCommissionAgentSReport = AccessRight("Read", Metadata.Documents.ConsignmentReportFromCustomer)
		And AccessRight("View", Metadata.Documents.ConsignmentReportFromCustomer);
	ReadingSalesOfGoodsServices = AccessRight("Read", Metadata.Documents.CustomerInvoice)
		And AccessRight("View", Metadata.Documents.CustomerInvoice);
		
	ReadingOrderToProcessor2_5 = AccessRight("Read", Metadata.Documents.SubcontractOrder2_5)
		And AccessRight("View", Metadata.Documents.SubcontractOrder2_5);
	ReadingGiverSOrder2_5 = AccessRight("Read", Metadata.Documents.MaterialProviderOrder2_5)
							 And AccessRight("View", Metadata.Documents.MaterialProviderOrder2_5);
	ReadingReportToGiver2_5 = AccessRight("Read", Metadata.Documents.ReportToMaterialProvider2_5)
							 And AccessRight("View", Metadata.Documents.ReportToMaterialProvider2_5);
	ReadReturnOfGoodsToSupplier = AccessRight("Read", Metadata.Documents.ReturnOfGoodsToVendor)
		And AccessRight("View", Metadata.Documents.ReturnOfGoodsToVendor);
	
	// Reference books.
	ReadingContractsOfCounterparties = AccessRight("Read", Metadata.Catalogs.CounterpartyContracts)
		And AccessRight("View", Metadata.Catalogs.CounterpartyContracts);
	
	// The calculation of the indicators
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	QueryText = "SELECT ALLOWED
	|	LettersOfAuthority.Ref,
	|	LettersOfAuthority.DocumentBasis,
	|	LettersOfAuthority.AuthorizationLetterType,
	|	LettersOfAuthority.Status,
	|	LettersOfAuthority.ValidityEndDate,
	|	LettersOfAuthority.EmployeeResponsible
	|INTO IssuedLettersOfAuthority
	|FROM
	|	Document.IssuedLetterOfAuthority AS LettersOfAuthority
	|WHERE
	|	NOT LettersOfAuthority.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IssuedLettersOfAuthority.DocumentBasis
	|INTO GroundsForPowersOfAttorneyForGoods
	|FROM
	|	IssuedLettersOfAuthority AS IssuedLettersOfAuthority
	|WHERE
	|	NOT IssuedLettersOfAuthority.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IssuedLettersOfAuthority.DocumentBasis
	|INTO GroundsForPowersOfAttorneyForCash
	|FROM
	|	IssuedLettersOfAuthority AS IssuedLettersOfAuthority
	|WHERE
	|	IssuedLettersOfAuthority.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash);";
	
	If AvailabilityOfOrdersGoods Then
		
		QueryText = QueryText +
		"SELECT ALLOWED
		|	TableOfOrdersReceipt.PurchaseOrder AS Ref
		|INTO OrdersReceived
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, VALUETYPE(PurchaseOrder) IN (&DocumentTypes)) AS TableOfOrdersReceipt
		|WHERE
		|	TableOfOrdersReceipt.ToRegisterBalance > 0
		|	AND VALUETYPE(TableOfOrdersReceipt.PurchaseOrder) IN (&DocumentTypes)
		|
		|UNION ALL
		|
		|SELECT
		|	TableOfOrdersReturn.ReferenceOrder
		|FROM
		|	#RequestsForReturnsTurnoverExpanded AS TableOfOrdersReturn
		|WHERE
		|	(TableOfOrdersReturn.ForRegistrationOnReturnsQuantityTurnover -
		|		TableOfOrdersReturn.IssuedByReturnsQuantityTurnover) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	TableOfOrdersReturnN.Ref
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS TableOfOrdersReturnN
		|WHERE
		|	TableOfOrdersReturnN.ThisIsOrderAsInvoice
		|	AND TableOfOrdersReturnN.Posted
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT OrdersReceived.Ref) AS NumberOfReceipts
		|INTO DeliveryReferences
		|FROM
		|	OrdersReceived AS OrdersReceived
		|		LEFT JOIN GroundsForPowersOfAttorneyForGoods AS GroundsForPowersOfAttorneyForGoods
		|		ON (GroundsForPowersOfAttorneyForGoods.DocumentBasis = OrdersReceived.Ref)
		|WHERE
		|	GroundsForPowersOfAttorneyForGoods.DocumentBasis IS NULL;";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"NOT ReferenceOrder.ThisIsOrderAsInvoice
			|		AND ReferenceOrder IN
			|			(SELECT
			|				Open_Orders.ReferenceOrder AS ReferenceOrder
			|			FROM
			|				InformationRegister.ShipmentAndReturnReferencesToFulfill AS Open_Orders)";
		TableFormationParameters.Group = "ReferenceOrder";
		TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
		TableFormationParameters.Resources = "Count";
		
		RequestsForReturnsTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = StrReplace(QueryText,
			"#RequestsForReturnsTurnoverExpanded",
			RequestsForReturnsTurnoverExpanded);
		
		DocumentTypes = New Array;
		If ReadOrderToSupplier Then
			DocumentTypes.Add(Type("DocumentRef.PurchaseOrder"));
		EndIf;
		
		If ReadingOrderToProcessor2_5 Then
			DocumentTypes.Add(Type("DocumentRef.SubcontractOrder2_5"));
		EndIf;

		Query.SetParameter("DocumentTypes", DocumentTypes);
	EndIf;
	
	If AvailabilityOfDSOrders Then
		
		QueryText = QueryText + "
		|SELECT
		|	ARAPObjects.Ref AS ARAPObject
		|INTO ARAPObjects
		|FROM Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	(VALUETYPE(ARAPObjects.Object) IN (&DocumentTypes)
		|	OR VALUETYPE(ARAPObjects.Object) = TYPE(Document.ReturnOfGoodsToVendor))
		|	AND NOT ARAPObjects.DeletionMark
		|;
		|SELECT ALLOWED
		|	CustomersARAPAccounting.ARAPObject.Object AS Ref
		|INTO DebtDocuments
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject IN (SELECT ARAPObject FROM ARAPObjects)) AS CustomersARAPAccounting
		|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
		|		ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionKeys.DimensionKey
		|WHERE
		|	CustomersARAPAccounting.AmountDueBalance - CustomersARAPAccounting.BeingPaidBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	VendorsARAPAccounting.ARAPObject.Object
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(, ARAPObject IN (SELECT ARAPObject FROM ARAPObjects)) AS VendorsARAPAccounting
		|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
		|		ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionKeys.DimensionKey
		|WHERE
		|	VendorsARAPAccounting.AmountDueBalance > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT DebtDocuments.Ref) AS DocumentsToBePaid
		|INTO DocumentsForPayment
		|FROM
		|	DebtDocuments AS DebtDocuments
		|		LEFT JOIN GroundsForPowersOfAttorneyForCash AS GroundsForPowersOfAttorneyForCash
		|		ON (GroundsForPowersOfAttorneyForCash.DocumentBasis = DebtDocuments.Ref)
		|WHERE
		|	GroundsForPowersOfAttorneyForCash.DocumentBasis IS NULL;";
		
		DocumentTypes = New Array;
		If ReadingCustomerOrder Then
			DocumentTypes.Add(Type("DocumentRef.SalesOrder"));
		EndIf;
		If ReadingSalesOfGoodsServices Then
			DocumentTypes.Add(Type("DocumentRef.CustomerInvoice"));
		EndIf;
		If ReadRequestForReturnOfGoodsFromCustomer Then
			DocumentTypes.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
		EndIf;
		If ReadingActOfCompletedWorks Then
			DocumentTypes.Add(Type("DocumentRef.CustomerInvoiceServices"));
		EndIf;
		If NetSalesOfServicesOtherAssets Then
			DocumentTypes.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
		EndIf;
		If ReadReturnOfGoodsToSupplier Then
			DocumentTypes.Add(Type("DocumentRef.ReturnOfGoodsToVendor"));
		EndIf;
		If ReadingCommissionAgentSReport Then
			DocumentTypes.Add(Type("DocumentRef.ConsignmentReportFromCustomer"));
		EndIf;
		If ReadingContractsOfCounterparties Then
			DocumentTypes.Add(Type("CatalogRef.CounterpartyContracts"));
		EndIf;
		
		If ReadingReportToGiver2_5 Then
			DocumentTypes.Add(Type("DocumentRef.ReportToMaterialProvider2_5"));
		EndIf;
		If ReadingGiverSOrder2_5 Then
			DocumentTypes.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
		EndIf;
		Query.SetParameter("DocumentTypes", DocumentTypes);
	EndIf;
	
	QueryText = QueryText + "
	|SELECT ALLOWED
	|	NULL AS OrdersForIssuingPowerOfAttorneyToReceiveGoods,
	|	NULL AS OrdersForIssuingPowerOfAttorneyToReceiveCash,
	|	COUNT(DISTINCT CASE
	|			WHEN DocumentLetterOfAuthority.Status = VALUE(Enum.StatusesOfAuthorizationLetters.Issued)
	|				THEN DocumentLetterOfAuthority.Ref
	|			ELSE NULL
	|		END) AS IssuedLettersOfAuthority,
	|	COUNT(DISTINCT CASE
	|			WHEN DocumentLetterOfAuthority.ValidityEndDate <= &UpdateDate
	|					AND DocumentLetterOfAuthority.ValidityEndDate <> DATETIME(1, 1, 1)
	|					AND DocumentLetterOfAuthority.Status = VALUE(Enum.StatusesOfAuthorizationLetters.Issued)
	|				THEN DocumentLetterOfAuthority.Ref
	|			ELSE NULL
	|		END) AS IssuedPowersOfAttorneyExpiringForToday,
	|	COUNT(DISTINCT CASE
	|			WHEN DocumentLetterOfAuthority.ValidityEndDate < &UpdateDate
	|					AND DocumentLetterOfAuthority.ValidityEndDate <> DATETIME(1, 1, 1)
	|					AND DocumentLetterOfAuthority.Status = VALUE(Enum.StatusesOfAuthorizationLetters.Issued)
	|				THEN DocumentLetterOfAuthority.Ref
	|			ELSE NULL
	|		END) AS IssuedPowerOfAttorneyExpired
	|INTO TableOfIndicators
	|FROM
	|	IssuedLettersOfAuthority AS DocumentLetterOfAuthority
	|WHERE
	|	DocumentLetterOfAuthority.EmployeeResponsible = &User
	|";
	
	If AvailabilityOfOrdersGoods Then
		
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	DeliveryReferences.NumberOfReceipts,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL
		|FROM DeliveryReferences";
	EndIf;
	
	If AvailabilityOfDSOrders Then
		
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	NULL,
		|	DocumentsForPayment.DocumentsToBePaid,
		|	NULL,
		|	NULL,
		|	NULL
		|FROM DocumentsForPayment";
		
	EndIf;
	
	Query.Text = QueryText;
	ToDoListInternal.SetCommonQueryParameters(Query, CommonQueryParameters);
	Query.Execute();
	
	Query.Text =
	"SELECT
	|		&AvailabilityOfOrdersGoods,
	|		&AvailabilityOfDSOrders,
	|		SUM(TableOfIndicators.IssuedLettersOfAuthority) AS IssuedLettersOfAuthority,
	|		SUM(TableOfIndicators.IssuedPowersOfAttorneyExpiringForToday) AS IssuedPowersOfAttorneyExpiringForToday,
	|		SUM(TableOfIndicators.IssuedPowerOfAttorneyExpired) AS IssuedPowerOfAttorneyExpired
	|FROM
	|	TableOfIndicators AS TableOfIndicators";
	
	// Let's remove the service comments from the request text - "unlock" the request lines
	Query.Text = StrReplace(Query.Text, "&AvailabilityOfOrdersGoods,", 
		?(AvailabilityOfOrdersGoods, "SUM(TableOfIndicators.OrdersForIssuingPowerOfAttorneyToReceiveGoods) AS OrdersForIssuingPowerOfAttorneyToReceiveGoods,", ""));
	Query.Text = StrReplace(Query.Text, "&AvailabilityOfDSOrders,", 
		?(AvailabilityOfDSOrders, "SUM(TableOfIndicators.OrdersForIssuingPowerOfAttorneyToReceiveCash) AS OrdersForIssuingPowerOfAttorneyToReceiveCash,", ""));
	Result = ToDoListInternal.NumericUserTasksIndicators(Query);
	
	// Filling out cases.
	// Power of Attorney to receive the MC
	// Dispositions of the form of trustworthin the receipt of goods
	ThereAreOrdersToIssuePowerOfAttorneyToReceiveGoods = False;
	If AvailabilityOfOrdersGoods Then
		FilterParameters = New Structure;
		FilterParameters.Insert("State", Enums.StatusesOfAuthorizationLetters.NotIssued);
		FilterParameters.Insert("Relevance", "");
		FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
		FilterParameters.Insert("EmployeeResponsible", CommonQueryParameters.User);
		FilterParameters.Insert("Person", Catalogs.Persons.EmptyRef());
		FilterParameters.Insert("PowerOfAttorneyRequired", True);
		FilterParameters.Insert("ThereIsLetterOfAuthority", False);
		
		FormParameters = New Structure;
		FormParameters.Insert("QuickFilterStructure", FilterParameters);
		FormParameters.Insert("OrderStatus_3", NStr("vi = 'Tạo giấy ủy nhiệm cần thiết';
													|ru = 'Требующие создания доверенности';
													|en = 'Authorization letter is required'; fa = 'وکالت‌نامه الزامی است';
													|it = 'Le deleghe da generare';
													|pl = 'Wymagające utworzenia pełnomocnictwa';
													|tr = 'Bir yetki belgesi oluşturulmasının gerekli kılınması'"));
		FormParameters.Insert("LetterOfAuthorityExistence", True);
		FormParameters.Insert("CurrentPageName", "PageOfTheOrderForRegistration");
		
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = "LettersOfAuthorityForInventoryReceipt";
		UserTaskParent.Presentation  = NStr("vi = 'Giấy ủy quyền tiếp nhận hàng hóa';
											|ru = 'Доверенности на получение ТМЦ';
											|en = 'Authorization letters for inventory receipt'; fa = 'Authorization letters for inventory receipt';
											|it = 'Deleghe per il ritiro di Beni e materiali';
											|pl = 'Pełnomocnictwa do odbioru zapasów';
											|tr = 'Stok alınması için yetki belgesi'");
		UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "OrdersForIssuingPowerOfAttorneyToReceiveGoods";
		ToDoItem.HasToDoItems       = Result.OrdersForIssuingPowerOfAttorneyToReceiveGoods > 0;
		ToDoItem.Presentation  = NStr("vi = 'Cơ sở để lập (nhận hàng hóa)';
										|ru = 'Основания для оформления (получение товаров)';
										|en = 'Bases for issuing (goods receipt)'; fa = 'مبانی صدور (دریافت کالا)';
										|it = 'Causali per formalizzazione (ricevimento delle merci)';
										|pl = 'Podstawy do sporządzenia (odbiór towarów)';
										|tr = 'Düzenleme gerekçesi (malların makbuzu)'");
		ToDoItem.Count     = Result.OrdersForIssuingPowerOfAttorneyToReceiveGoods;
		ToDoItem.Important         = False;
		ToDoItem.Form          = FormName;
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Owner       = "LettersOfAuthorityForInventoryReceipt";
		
		ThereAreOrdersToIssuePowerOfAttorneyToReceiveGoods = ToDoItem.HasToDoItems;
		UserTaskParent.HasToDoItems = ToDoItem.HasToDoItems;
	EndIf;
	
	// OrdersForIssuingPowerOfAttorneyToReceiveCash
	ThereAreOrdersToIssuePowerOfAttorneyToReceiveCash = False;
	If AvailabilityOfDSOrders Then
		FilterParameters = New Structure;
		FilterParameters.Insert("State", Enums.StatusesOfAuthorizationLetters.NotIssued);
		FilterParameters.Insert("Relevance", "");
		FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
		FilterParameters.Insert("EmployeeResponsible", CommonQueryParameters.User);
		FilterParameters.Insert("Person", Catalogs.Persons.EmptyRef());
		FilterParameters.Insert("PowerOfAttorneyRequired", True);
		FilterParameters.Insert("ThereIsLetterOfAuthority", False);
		
		FormParameters = New Structure;
		FormParameters.Insert("QuickFilterStructure", FilterParameters);
		FormParameters.Insert("OrderStatus_3", NStr("vi = 'Tạo giấy ủy nhiệm cần thiết';
													|ru = 'Требующие создания доверенности';
													|en = 'Authorization letter is required'; fa = 'وکالت‌نامه الزامی است';
													|it = 'Le deleghe da generare';
													|pl = 'Wymagające utworzenia pełnomocnictwa';
													|tr = 'Bir yetki belgesi oluşturulmasının gerekli kılınması'"));
		FormParameters.Insert("LetterOfAuthorityExistence", True);
		FormParameters.Insert("CurrentPageName", "PageOfTheOrderForRegistrationOfTheDS");
		
		// LettersOfAuthorityForInventoryReceipt
		BusinessParentSales = ToDoList.Add();
		BusinessParentSales.Id  = "PowerOfAttorneyForCashReceipt";
		BusinessParentSales.Presentation  = NStr("vi = 'Giấy ủy quyền thu tiền';
												|ru = 'Доверенности на получение наличных ДС';
												|en = 'Authorization letters for receiving cash'; fa = 'وکالت‌نامه‌های دریافت وجه نقد';
												|it = 'Deleghe per incasso dei fondi monetari in contanti';
												|pl = 'Pełnomocnictwo do odbioru gotówki';
												|tr = 'Nakit makbuzu için yetki belgesi'");
		BusinessParentSales.Owner       = Metadata.Subsystems.Sales;
	
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "OrdersForIssuingPowerOfAttorneyToReceiveCash";
		ToDoItem.HasToDoItems       = Result.OrdersForIssuingPowerOfAttorneyToReceiveCash > 0;
		ToDoItem.Presentation  = NStr("vi = 'Cơ sở để lập (nhận tiền mặt)';
										|ru = 'Основания для оформления (получение наличных ДС)';
										|en = 'Bases for issuing (receiving cash)'; fa = 'مبانی صدور (دریافت وجه نقد)';
										|it = 'Causali per formalizzazione (incasso fondi monetari in contanti)';
										|pl = 'Podstawy do sporządzenia odbiór gotówkowych środków pieniężnych)';
										|tr = 'Düzenleme gerekçesi (Nakit makbuzu)'");
		ToDoItem.Count     = Result.OrdersForIssuingPowerOfAttorneyToReceiveCash;
		ToDoItem.Important         = False;
		ToDoItem.Form          = FormName;
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Owner       = "PowerOfAttorneyForCashReceipt";
		
		ThereAreOrdersToIssuePowerOfAttorneyToReceiveCash = ToDoItem.HasToDoItems;
		BusinessParentSales.HasToDoItems = ToDoItem.HasToDoItems;
	EndIf;
	
	BusinessParentFinance = ToDoList.Add();
	BusinessParentFinance.Id  = "IssuedPowerOfAttorneyParent";
	BusinessParentFinance.Presentation  = NStr("vi = 'Giấy ủy quyền đã cấp';
												|ru = 'Выданные доверенности';
												|en = 'Issued authorization letters'; fa = 'وکالت‌نامه‌های صادرشده';
												|it = 'Deleghe rilasciate';
												|pl = 'Wydanie pełnomocnictwa';
												|tr = 'Verilmiş yetki belgeleri'");
	BusinessParentFinance.Owner       = Metadata.Subsystems.TreasuryAndARAPAccounting;
	
	// IssuedLettersOfAuthority
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Enums.StatusesOfAuthorizationLetters.Issued);
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("EmployeeResponsible", CommonQueryParameters.User);
	FilterParameters.Insert("Person", Catalogs.Persons.EmptyRef());
	FilterParameters.Insert("ThereIsLetterOfAuthority", False);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("OrderStatus_3", NStr("vi = 'Tạo giấy ủy nhiệm cần thiết';
												|ru = 'Требующие создания доверенности';
												|en = 'Authorization letter is required'; fa = 'وکالت‌نامه الزامی است';
												|it = 'Le deleghe da generare';
												|pl = 'Wymagające utworzenia pełnomocnictwa';
												|tr = 'Bir yetki belgesi oluşturulmasının gerekli kılınması'"));
	FormParameters.Insert("LetterOfAuthorityExistence", True);
	FormParameters.Insert("CurrentPageName", "PowerOfAttorneyPageForReceivingGoods");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "IssuedLettersOfAuthority";
	ToDoItem.HasToDoItems       = Result.IssuedLettersOfAuthority > 0;
	ToDoItem.Presentation  = NStr("vi = 'Giấy ủy quyền đã cấp';
									|ru = 'Выданные доверенности';
									|en = 'Issued authorization letters'; fa = 'وکالت‌نامه‌های صادرشده';
									|it = 'Deleghe rilasciate';
									|pl = 'Wydanie pełnomocnictwa';
									|tr = 'Verilmiş yetki belgeleri'");
	ToDoItem.Count     = Result.IssuedLettersOfAuthority;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "IssuedPowerOfAttorneyParent";
	
	// IssuedPowersOfAttorneyExpiringForToday
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Enums.StatusesOfAuthorizationLetters.Issued);
	FilterParameters.Insert("Relevance", "Today");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("EmployeeResponsible", CommonQueryParameters.User);
	FilterParameters.Insert("Person", Catalogs.Persons.EmptyRef());
	FilterParameters.Insert("ThereIsLetterOfAuthority", False);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("OrderStatus_3", NStr("vi = 'Tạo giấy ủy nhiệm cần thiết';
												|ru = 'Требующие создания доверенности';
												|en = 'Authorization letter is required'; fa = 'وکالت‌نامه الزامی است';
												|it = 'Le deleghe da generare';
												|pl = 'Wymagające utworzenia pełnomocnictwa';
												|tr = 'Bir yetki belgesi oluşturulmasının gerekli kılınması'"));
	FormParameters.Insert("LetterOfAuthorityExistence", True);
	FormParameters.Insert("CurrentPageName", "PowerOfAttorneyPageForReceivingGoods");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "IssuedPowersOfAttorneyExpiringForToday";
	ToDoItem.HasToDoItems       = Result.IssuedPowersOfAttorneyExpiringForToday > 0;
	ToDoItem.Presentation  = NStr("vi = 'Giấy ủy quyền mà hôm nay hết hạn';
									|ru = 'Доверенности, истекающие сегодня';
									|en = 'Authorization letters expiring today'; fa = 'Authorization letters expiring today';
									|it = 'Deleghe in scadenza oggi';
									|pl = 'Pełnomocnictwa, wygasające dzisiaj';
									|tr = 'Bugün sona eren yetki belgeleri'");
	ToDoItem.Count     = Result.IssuedPowersOfAttorneyExpiringForToday;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "IssuedPowerOfAttorneyParent";
	
	// IssuedPowerOfAttorneyExpired
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Enums.StatusesOfAuthorizationLetters.Issued);
	FilterParameters.Insert("Overdue", "Today");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("EmployeeResponsible", CommonQueryParameters.User);
	FilterParameters.Insert("Person", Catalogs.Persons.EmptyRef());
	FilterParameters.Insert("ThereIsLetterOfAuthority", False);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("OrderStatus_3", NStr("vi = 'Tạo giấy ủy nhiệm cần thiết';
												|ru = 'Требующие создания доверенности';
												|en = 'Authorization letter is required'; fa = 'وکالت‌نامه الزامی است';
												|it = 'Le deleghe da generare';
												|pl = 'Wymagające utworzenia pełnomocnictwa';
												|tr = 'Bir yetki belgesi oluşturulmasının gerekli kılınması'"));
	FormParameters.Insert("LetterOfAuthorityExistence", True);
	FormParameters.Insert("CurrentPageName", "PowerOfAttorneyPageForReceivingGoods");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "IssuedPowerOfAttorneyExpired";
	ToDoItem.HasToDoItems       = Result.IssuedPowerOfAttorneyExpired > 0;
	ToDoItem.Presentation  = NStr("vi = 'Giấy ủy quyền đã quá hạn';
									|ru = 'Просроченные доверенности';
									|en = 'Overdue authorization letters'; fa = 'Overdue authorization letters';
									|it = 'Deleghe scadute';
									|pl = 'Zaległe pełnomocnictwa';
									|tr = 'Süresi dolmuş yetki belgeleri'");
	ToDoItem.Count     = Result.IssuedPowerOfAttorneyExpired;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "IssuedPowerOfAttorneyParent";
	
	If Result.IssuedLettersOfAuthority > 0
		Or Result.IssuedPowersOfAttorneyExpiringForToday > 0
		Or Result.IssuedPowerOfAttorneyExpired > 0 Then
		BusinessParentFinance.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

#EndRegion

#Region Other

#Region CreatingHyperlinkInPurchaseLog 

Function TextOfRequestForOrdersForGoods(NoPowerOfAttorney = Undefined) Export

	QueryText = 
	"SELECT ALLOWED
	|	MIN(LettersOfAuthority.Ref) AS PowerOfAttorneyCreated,
	|	LettersOfAuthority.DocumentBasis AS DocumentBasis
	|INTO LettersOfAuthority
	|FROM
	|	Document.IssuedLetterOfAuthority AS LettersOfAuthority
	|WHERE
	|	NOT LettersOfAuthority.DeletionMark
	|	AND LettersOfAuthority.AuthorizationLetterType <> VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash)
	|
	|GROUP BY
	|	LettersOfAuthority.DocumentBasis
	|
	|INDEX BY
	|	DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ScheduledReceipt.ReferenceOrder.Ref AS Ref,
	|	ScheduledReceipt.ReferenceOrder.DeletionMark AS DeletionMark,
	|	VALUETYPE(ScheduledReceipt.ReferenceOrder) AS TypeOfOrder_,
	|	ScheduledReceipt.ReferenceOrder.Date AS Date,
	|	ScheduledReceipt.ReferenceOrder.Number AS Number,
	|	ScheduledReceipt.ReferenceOrder.Partner AS Partner,
	|	ScheduledReceipt.ReferenceOrder.Counterparty AS Counterparty,
	|	ScheduledReceipt.ReferenceOrder.Organization AS Organization,
	|	CASE
	|		WHEN
	|			VALUETYPE(ScheduledReceipt.ReferenceOrder) = TYPE(Document.SubcontractOrder2_5) OR
	|				FALSE
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE ScheduledReceipt.ReferenceOrder.Warehouse
	|	END AS Warehouse,
	|	ScheduledReceipt.ReferenceOrder.Currency AS Currency,
	|	ScheduledReceipt.ReferenceOrder.Manager AS Manager,
	|	ScheduledReceipt.ReferenceOrder.DocumentAmount AS DocumentAmount,
	|	VALUE(Catalog.Priorities.EmptyRef) AS Priority,
	|	ScheduledReceipt.ReferenceOrder.BusinessOperation AS BusinessOperation,
	|	PRESENTATION(ScheduledReceipt.ReferenceOrder.BusinessOperation) AS BusinessOperationPresentation,
	|	ScheduledReceipt.ReferenceOrder.Comment AS Comment,
	|	(LettersOfAuthority.PowerOfAttorneyCreated IS NOT NULL) AS ThereIsLetterOfAuthority,
	|	1 AS PictureOfPriority
	|FROM
	|	#QueryTextScheduledReceipt AS ScheduledReceipt
	|		LEFT JOIN LettersOfAuthority AS LettersOfAuthority
	|		ON ScheduledReceipt.ReferenceOrder = LettersOfAuthority.DocumentBasis
	|WHERE
	|	NOT ScheduledReceipt.ReferenceOrder.Ref IS NULL 
	|	AND (VALUETYPE(ScheduledReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
	|			OR VALUETYPE(ScheduledReceipt.ReferenceOrder) = TYPE(Document.SubcontractOrder2_5)
	|			OR VALUETYPE(ScheduledReceipt.ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|			OR VALUETYPE(ScheduledReceipt.ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer))
	|	AND &FilterCriterion";
	
	QueryTextScheduledReceipt = New Array;
	If AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders) Then
		QueryTextScheduledReceipt.Add("
		|SELECT
		|		PurchaseOrders.PurchaseOrder AS ReferenceOrder
		|	FROM
		|		AccumulationRegister.PurchaseOrders.Balance AS PurchaseOrders
		|	
		|	GROUP BY
		|		PurchaseOrders.PurchaseOrder
		|	
		|	HAVING
		|		SUM(PurchaseOrders.ToRegisterBalance) > 0");
	EndIf;
	If AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences) Then
		
		QueryTextShipmentReferences = "
		|	SELECT
		|		RequestsForReturn.ReferenceOrder AS ReferenceOrder
		|	FROM
		|		#RequestsForReturnsTurnoverExpanded AS RequestsForReturn
		|	
		|	GROUP BY
		|		RequestsForReturn.ReferenceOrder
		|	
		|	HAVING
		|		SUM(RequestsForReturn.ForRegistrationOnReturnsQuantityTurnover -
		|			RequestsForReturn.IssuedByReturnsQuantityTurnover) > 0";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"NOT ReferenceOrder.ThisIsOrderAsInvoice
			|		AND ReferenceOrder IN
			|			(SELECT
			|				Open_Orders.ReferenceOrder AS ReferenceOrder
			|			FROM
			|				InformationRegister.ShipmentAndReturnReferencesToFulfill AS Open_Orders)";
		TableFormationParameters.Group = "ReferenceOrder";
		TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
		TableFormationParameters.Resources = "Count";
		
		RequestsForReturnsTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryTextShipmentReferences = StrReplace(QueryTextShipmentReferences,
			"#RequestsForReturnsTurnoverExpanded",
			RequestsForReturnsTurnoverExpanded);
		
		QueryTextScheduledReceipt.Add(QueryTextShipmentReferences);
		
	EndIf;
	If AccessRight("View", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
		QueryTextScheduledReceipt.Add("
		|	SELECT
		|		RequestsForReturn.Ref AS ReferenceOrder
		|	FROM
		|		Document.RequestForReturnOfGoodsFromCustomer AS RequestsForReturn
		|	WHERE
		|		RequestsForReturn.ThisIsOrderAsInvoice
		|		AND RequestsForReturn.Posted");
	EndIf;
	If QueryTextScheduledReceipt.Count() = 0 Then
		Raise NStr("vi = 'Người dùng không có đủ quyền để thực hiện các Giao dịch trên cơ sở dữ liệu';
					|ru = 'У пользователя недостаточно прав для исполнения операции над базой данных';
					|en = 'User has insufficient rights to perform operations with the database'; fa = 'User has insufficient rights to perform operations with the database';
					|it = 'Utente non ha i diritti sufficienti per eseguire l''operazione sul database';
					|pl = 'Użytkownik ma niewystarczająco uprawnień do wykonania operacji z bazą danych';
					|tr = 'Kullanıcının bir veritabanı işlemini gerçekleştirmek için yeterli hakkı yok'");
	EndIf;
	QueryTextScheduledReceipt = StrConcat(QueryTextScheduledReceipt,"
		|UNION ALL
		|");
	QueryTextScheduledReceipt = "("+QueryTextScheduledReceipt+")";
	QueryText = StrReplace(QueryText,"#QueryTextScheduledReceipt",QueryTextScheduledReceipt);
	
	FilterCriterion = "";
	
	If ValueIsFilled(NoPowerOfAttorney) Then
		QueryText = StrReplace(QueryText,"&FilterCriterion", "LettersOfAuthority.PowerOfAttorneyCreated IS NULL");
	Else
		QueryText = StrReplace(QueryText,"AND &FilterCriterion", "");
	EndIf;
	
	Return QueryText
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Parameters.Property("AuthorizationLetterType") And Parameters.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash Then
		If Not AccessRight("Read", Metadata.Documents.IssuedLetterOfAuthority)
			Or Not GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt") Then
			
			Return Undefined
		EndIf;
		
		QueryText = QueryTextPowerOfAttorneyForCashReceipt();
		
		Query = New Query;
		Query.Text = QueryText;
		
	Else
		
		UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
		If Not (GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt")
				And AccessRight("Read", Metadata.Documents.IssuedLetterOfAuthority)
				And (AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
					Or AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
						And UseAdvancedFeaturesOfSalesOrder
					Or AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer)
						And Not UseAdvancedFeaturesOfSalesOrder)) Then
			Return Undefined;
		EndIf;
		
		QueryText = TextOfRequestForOrdersForGoods(True);
		
		Query = New Query;
		Query.Text = QueryText;
	EndIf;
	HyperlinkText = NStr("vi = 'Giấy ủy quyền';
						|ru = 'Доверенности';
						|en = 'Authorization letters'; fa = 'وکالت‌نامه‌ها';
						|it = 'Deleghe';
						|pl = 'Uprawnienia';
						|tr = 'Yetki belgeleri'");
	
	FormNameWorkplacePowerOfAttorney = "Document.IssuedLetterOfAuthority.Form.DocumentsListForm";
	If Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			FormNameWorkplacePowerOfAttorney);
	Else
		Return New FormattedString(HyperlinkText,,,,
			FormNameWorkplacePowerOfAttorney);
	EndIf;
	
EndFunction

Function TextOfRequestForCashOrders() Export
	
	// Registers.
	ReadCustomerSettlements = AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting);
	ReadSettlementsWithSuppliers = AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting);
	
	// Documents.
	ReadingCustomerOrder = AccessRight("View", Metadata.Documents.SalesOrder);
	ReadRequestForReturnOfGoodsFromCustomer = AccessRight("View", Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	ReadingActOfCompletedWorks = AccessRight("View", Metadata.Documents.CustomerInvoiceServices);
	NetSalesOfServicesOtherAssets = AccessRight("View", Metadata.Documents.CustomerInvoiceServicesAndAssets);
	ReadingCommissionAgentSReport = AccessRight("View", Metadata.Documents.ConsignmentReportFromCustomer);
	ReadingSalesOfGoodsServices = AccessRight("View", Metadata.Documents.CustomerInvoice);
	
	ReadingGiverSOrder2_5 = AccessRight("View", Metadata.Documents.MaterialProviderOrder2_5);
	ReadingReportToGiver2_5 = AccessRight("View", Metadata.Documents.ReportToMaterialProvider2_5);
	ReadReturnOfGoodsToSupplier = AccessRight("View", Metadata.Documents.ReturnOfGoodsToVendor);
	
	// Reference books.
	ReadingContractsOfCounterparties = AccessRight("View", Metadata.Catalogs.CounterpartyContracts);
	
	QueriesTexts = New Array();
	
	TemplateText = "
	|SELECT
	|	DocumentOfARAPAccounting.Ref AS Ref,
	|	DocumentOfARAPAccounting.DeletionMark AS DeletionMark,
	|	DocumentOfARAPAccounting.Date AS Date,
	|	DocumentOfARAPAccounting.Number AS Number,
	|	VALUETYPE(DocumentOfARAPAccounting.Ref) AS TypeOfOrder_,
	|	Calculations.Currency AS Currency,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	&CashReceiptFromCustomerPresentation AS BusinessOperationPresentation,
	|	DimensionKeys.Partner AS Partner,
	|	DimensionKeys.Partner.Description AS PartnerPresentation,
	|	DimensionKeys.Counterparty AS Counterparty,
	|	DimensionKeys.Organization AS Organization,
	|	DocumentOfARAPAccounting.Manager AS Manager,
	|	DocumentOfARAPAccounting.Manager AS EmployeeResponsible,
	|	DocumentOfARAPAccounting.DocumentAmount AS DocumentAmount,
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance AS AmountDueBalance
	|FROM
	|	Document.SalesOrder AS DocumentOfARAPAccounting
	|		INNER JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
	|				,
	|				NOT ARAPObject.Object = UNDEFINED
	|					AND ARAPObject.Object REFS Document.SalesOrder) AS Calculations
	|		ON (Calculations.ARAPObject.Object = DocumentOfARAPAccounting.Ref)
	|			AND (Calculations.AmountDueBalance - Calculations.BeingPaidBalance > 0)
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|		ON (Calculations.AccountingDimensionByPartners = DimensionKeys.DimensionKey)
	|WHERE
	|	DocumentOfARAPAccounting.PaymentMethod <> VALUE(Enum.PaymentForms.BankAccountPayment)
	|	AND DocumentOfARAPAccounting.PaymentMethod <> VALUE(Enum.PaymentForms.InstantPayments)";
		
	If ReadCustomerSettlements Then
		
		TextHOPresentation = NStr("vi = '""Nhận thanh toán từ khách hàng""';
									|ru = '""Поступление оплаты от клиента""';
									|en = '""Customer payment""'; fa = '""Customer payment""';
									|it = '""Arrivo di pagamento dal cliente""';
									|pl = '""Wpływ płatności od klienta""';
									|tr = '""Müşteriden ödeme alınması""'");
		
		// Customer's order.
		If ReadingCustomerOrder Then
			QueryText = TemplateText;
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		// Request for the return of goods from the client.
		If ReadRequestForReturnOfGoodsFromCustomer Then
			QueryText = StrReplace(TemplateText, "SalesOrder", Metadata.Documents.RequestForReturnOfGoodsFromCustomer.Name);
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		// The act of completed works.
		If ReadingActOfCompletedWorks Then
			QueryText = StrReplace(TemplateText, "SalesOrder", Metadata.Documents.CustomerInvoiceServices.Name);
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		// Sale of services of other assets.
		If NetSalesOfServicesOtherAssets Then
			QueryText = StrReplace(TemplateText, "SalesOrder", Metadata.Documents.CustomerInvoiceServicesAndAssets.Name);
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		// Commission agent's report.
		If ReadingCommissionAgentSReport Then
			QueryText = StrReplace(TemplateText, "SalesOrder", Metadata.Documents.ConsignmentReportFromCustomer.Name);
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		// Sale of goods and services.
		If ReadingSalesOfGoodsServices Then
			QueryText = StrReplace(TemplateText, "SalesOrder", Metadata.Documents.CustomerInvoice.Name);
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		
		
		// Giver's order (2.5)
		If ReadingGiverSOrder2_5 Then
			QueryText = StrReplace(TemplateText, "SalesOrder", Metadata.Documents.MaterialProviderOrder2_5.Name);
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		
		// Report to the giver (2.5)
		If ReadingReportToGiver2_5 Then
			QueryText = StrReplace(TemplateText, "SalesOrder", Metadata.Documents.ReportToMaterialProvider2_5.Name);
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		If ReadingContractsOfCounterparties Then
			QueryText = "
			|SELECT
			|	DocumentOfARAPAccounting.Ref AS Ref,
			|	DocumentOfARAPAccounting.DeletionMark AS DeletionMark,
			|	DocumentOfARAPAccounting.Date AS Date,
			|	DocumentOfARAPAccounting.Number AS Number,
			|	VALUETYPE(DocumentOfARAPAccounting.Ref) AS TypeOfOrder_,
			|	Calculations.Currency AS Currency,
			|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
			|	&CashReceiptFromCustomerPresentation AS BusinessOperationPresentation,
			|	DimensionKeys.Partner AS Partner,
			|	DimensionKeys.Partner.Description AS PartnerPresentation,
			|	DimensionKeys.Counterparty AS Counterparty,
			|	DimensionKeys.Organization AS Organization,
			|	DocumentOfARAPAccounting.Manager AS Manager,
			|	DocumentOfARAPAccounting.Manager AS EmployeeResponsible,
			|	0 AS DocumentAmount,
			|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance AS AmountDueBalance
			|FROM
			|	Catalog.CounterpartyContracts AS DocumentOfARAPAccounting
			|		INNER JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
			|				,
			|				ARAPObject.Object REFS Catalog.CounterpartyContracts) AS Calculations
			|		ON (Calculations.ARAPObject.Object = DocumentOfARAPAccounting.Ref)
			|			AND (Calculations.AmountDueBalance - Calculations.BeingPaidBalance > 0)
			|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
			|		ON (Calculations.AccountingDimensionByPartners = DimensionKeys.DimensionKey)";
			
			QueryText = StrReplace(QueryText, "&CashReceiptFromCustomerPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		
	EndIf;
	
	If ReadSettlementsWithSuppliers Then
		
		TextHOPresentation = NStr("vi = '""Trả lại từ nhà cung cấp""';
									|ru = '""Возврат от поставщика""';
									|en = '""Vendor refund""'; fa = '""Vendor refund""';
									|it = '""Reso dal fornitore""';
									|pl = '""Zwrot od dostawcy""';
									|tr = '""Tedarikçiden iade""'");
		
		QueryText = "
		|SELECT
		|	DocumentOfARAPAccounting.Ref AS Ref,
		|	DocumentOfARAPAccounting.DeletionMark AS DeletionMark,
		|	DocumentOfARAPAccounting.Date AS Date,
		|	DocumentOfARAPAccounting.Number AS Number,
		|	VALUETYPE(DocumentOfARAPAccounting.Ref) AS TypeOfOrder_,
		|	Calculations.Currency AS Currency,
		|	VALUE(Enum.BusinessTransactions.RefundFromVendor) AS BusinessOperation,
		|	&RefundFromVendorPresentation AS BusinessOperationPresentation,
		|	DimensionKeys.Partner AS Partner,
		|	DimensionKeys.Partner.Description AS PartnerPresentation,
		|	DimensionKeys.Counterparty AS Counterparty,
		|	DimensionKeys.Organization AS Organization,
		|	DocumentOfARAPAccounting.Manager AS Manager,
		|	DocumentOfARAPAccounting.Manager AS EmployeeResponsible,
		|	DocumentOfARAPAccounting.DocumentAmount AS DocumentAmount,
		|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance AS AmountDueBalance
		|FROM
		|	Document.ReturnOfGoodsToVendor AS DocumentOfARAPAccounting
		|		INNER JOIN AccumulationRegister.VendorsARAPAccounting.Balance(
		|				,
		|				NOT ARAPObject.Object = UNDEFINED
		|					AND ARAPObject.Object REFS Document.ReturnOfGoodsToVendor) AS Calculations
		|		ON (Calculations.ARAPObject.Object = DocumentOfARAPAccounting.Ref)
		|			AND (Calculations.AmountDueBalance - Calculations.BeingPaidBalance > 0)
		|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
		|		ON (Calculations.AccountingDimensionByPartners = DimensionKeys.DimensionKey)
		|";
		
		// Return of goods to the supplier.
		If ReadReturnOfGoodsToSupplier Then
			QueryText = StrReplace(QueryText, "&RefundFromVendorPresentation", TextHOPresentation);
			QueriesTexts.Add(QueryText);
		EndIf;
		
	EndIf;
	
	If QueriesTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	RequestTemplateText = "
		|SELECT ALLOWED
		|	Documents.Ref AS Ref,
		|	Documents.DeletionMark AS DeletionMark,
		|	Documents.Date AS Date,
		|	Documents.Number AS Number,
		|	Documents.TypeOfOrder_ AS TypeOfOrder_,
		|	Documents.Currency AS Currency,
		|	Documents.BusinessOperation AS BusinessOperation,
		|	Documents.BusinessOperationPresentation AS BusinessOperationPresentation,
		|	Documents.Partner AS Partner,
		|	Documents.PartnerPresentation AS PartnerPresentation,
		|	Documents.Counterparty AS Counterparty,
		|	Documents.Organization AS Organization,
		|	Documents.Manager AS Manager,
		|	Documents.EmployeeResponsible AS EmployeeResponsible,
		|	Documents.DocumentAmount AS DocumentAmount,
		|	Documents.AmountDueBalance AS AmountDueBalance
		|INTO SettlementDocuments
		|FROM SettlementDocumentsArePreliminary AS Documents
		|;";
	
	QueryText = StrReplace(RequestTemplateText, "SettlementDocumentsArePreliminary",
		"(" + StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
	
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	LettersOfAuthority.DocumentBasis
	|INTO IssuedLettersOfAuthority
	|FROM
	|	Document.IssuedLetterOfAuthority AS LettersOfAuthority
	|WHERE
	|	NOT LettersOfAuthority.DeletionMark
	|	AND LettersOfAuthority.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SettlementDocuments.Ref AS Ref,
	|	SettlementDocuments.DeletionMark AS DeletionMark,
	|	SettlementDocuments.Date AS Date,
	|	SettlementDocuments.Number AS Number,
	|	SettlementDocuments.TypeOfOrder_ AS TypeOfOrder_,
	|	SettlementDocuments.Currency AS Currency,
	|	SettlementDocuments.BusinessOperation AS BusinessOperation,
	|	SettlementDocuments.BusinessOperationPresentation AS BusinessOperationPresentation,
	|	SettlementDocuments.Partner AS Partner,
	|	SettlementDocuments.Partner.Description AS PartnerPresentation,
	|	SettlementDocuments.Counterparty AS Counterparty,
	|	SettlementDocuments.Organization AS Organization,
	|	SettlementDocuments.Manager AS Manager,
	|	SettlementDocuments.EmployeeResponsible AS EmployeeResponsible,
	|	SettlementDocuments.DocumentAmount AS DocumentAmount,
	|	SettlementDocuments.AmountDueBalance AS AmountDueBalance,
	|	VALUE(Catalog.Priorities.EmptyRef) AS Priority,
	|	CASE
	|		WHEN IssuedLettersOfAuthority.DocumentBasis IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereIsLetterOfAuthority,
	|	CASE
	|		WHEN IssuedLettersOfAuthority.DocumentBasis IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PowerOfAttorneyRequired,
	|	1 AS PictureOfPriority
	|FROM
	|	SettlementDocuments AS SettlementDocuments
	|		LEFT JOIN IssuedLettersOfAuthority AS IssuedLettersOfAuthority
	|		ON SettlementDocuments.Ref = IssuedLettersOfAuthority.DocumentBasis";
	
	Return QueryText;
	
EndFunction

Function QueryTextPowerOfAttorneyForCashReceipt()
	
	QueryText = 
	"SELECT ALLOWED TOP 1
	|	IssuedLetterOfAuthority.Ref
	|FROM
	|	Document.IssuedLetterOfAuthority AS IssuedLetterOfAuthority
	|WHERE
	|	IssuedLetterOfAuthority.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash)
	|	AND IssuedLetterOfAuthority.Status IN (VALUE(Enum.StatusesOfAuthorizationLetters.Issued),VALUE(Enum.StatusesOfAuthorizationLetters.NotIssued))";
	
	Return QueryText
	
EndFunction

// Generates a table of values for decrypting payments.
//
// Returns:
//  ValueTable:
//   * CashFlowItem - CatalogRef.CashFlowReportItems
//   * ARAPObject - CatalogRef.ARAPObjects
//   * Partner - CatalogRef.Partners
//   * ARAPCurrency - CatalogRef.Currencies
//   * MaturityDate - Date
//   * Sum - Number
//   * AmountARAP - Number
//
Function GetPaymentDecryptionTable() Export
	
	ARAPDetails = New ValueTable();
	ARAPDetails.Columns.Add("CashFlowItem", New TypeDescription("CatalogRef.CashFlowReportItems"));
	ARAPDetails.Columns.Add("ARAPObject",                New TypeDescription("CatalogRef.ARAPObjects"));
	ARAPDetails.Columns.Add("Partner",                       New TypeDescription("CatalogRef.Partners"));
	ARAPDetails.Columns.Add("ARAPCurrency",          New TypeDescription("CatalogRef.Currencies"));
	ARAPDetails.Columns.Add("MaturityDate",                 New TypeDescription("Date"));
	ARAPDetails.Columns.Add("Sum",                         New TypeDescription("Number"));
	ARAPDetails.Columns.Add("AmountARAP",           New TypeDescription("Number"));
	
	Return ARAPDetails;
	
EndFunction

#EndRegion

#Region CalculationOfPowerOfAttorneyStatus

Function CalculateStateOfPowerOfAttorney(ObjectsArray) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text = "SELECT
	|	PowerOfAttorneyForGoods.Ref AS Ref,
	|	PowerOfAttorneyForGoods.DocumentBasis AS DocumentBasis
	|INTO PowersOfAttorneyForGoods
	|FROM
	|	Document.IssuedLetterOfAuthority AS PowerOfAttorneyForGoods
	|WHERE
	|	PowerOfAttorneyForGoods.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveGoods)
	|	AND PowerOfAttorneyForGoods.Status = VALUE(Enum.StatusesOfAuthorizationLetters.Issued)
	|	AND PowerOfAttorneyForGoods.Ref IN(&ReferencesArrray)
	|
	|INDEX BY
	|	DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PowerOfAttorneyForCash_.Ref AS Ref
	|INTO PowerOfAttorneyForCash
	|FROM
	|	Document.IssuedLetterOfAuthority AS PowerOfAttorneyForCash_
	|WHERE
	|	PowerOfAttorneyForCash_.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash)
	|	AND PowerOfAttorneyForCash_.Status = VALUE(Enum.StatusesOfAuthorizationLetters.Issued)
	|	AND PowerOfAttorneyForCash_.Ref IN(&ReferencesArrray)
	|
	|UNION ALL
	|
	|SELECT
	|	PowerOfAttorneyForCash_.Ref
	|FROM
	|	Document.IssuedLetterOfAuthority AS PowerOfAttorneyForCash_
	|WHERE
	|	PowerOfAttorneyForCash_.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash)
	|	AND PowerOfAttorneyForCash_.Status = VALUE(Enum.StatusesOfAuthorizationLetters.UsedPartially)
	|	AND PowerOfAttorneyForCash_.Ref IN(&ReferencesArrray)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PowerOfAttorneyForCash.Ref AS Ref,
	|	SUM(CheckoutDocuments.DocumentAmount) AS AmountOfPayments
	|INTO Paid_
	|FROM
	|	Document.CashAccountReceiptNote AS CheckoutDocuments
	|		INNER JOIN PowerOfAttorneyForCash AS PowerOfAttorneyForCash
	|		ON (PowerOfAttorneyForCash.Ref = CheckoutDocuments.IssuedLetterOfAuthority)
	|			AND (CheckoutDocuments.Posted)
	|
	|GROUP BY
	|	PowerOfAttorneyForCash.Ref
	|
	|HAVING
	|	SUM(CheckoutDocuments.DocumentAmount) > 0
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PowersOfAttorneyForGoods.Ref AS Ref
	|INTO Received
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
	|		INNER JOIN PowersOfAttorneyForGoods AS PowersOfAttorneyForGoods
	|		ON (PowersOfAttorneyForGoods.DocumentBasis = VendorsARAPAccounting.ARAPObject.Object)
	|			AND (VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense))
	|			AND (NOT VendorsARAPAccounting.ToReceive = 0)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentIssuedLetterOfAuthority.Ref AS Ref,
	|	DocumentIssuedLetterOfAuthority.DeletionMark AS DeletionMark,
	|	PRESENTATION(DocumentIssuedLetterOfAuthority.Ref) AS Presentation,
	|	0 AS AmountOfPayments,
	|	FALSE AS ThereArePayments,
	|	NOT Received.Ref IS NULL AS HasGoodsReceipt
	|FROM
	|	Document.IssuedLetterOfAuthority AS DocumentIssuedLetterOfAuthority
	|		INNER JOIN PowersOfAttorneyForGoods AS PowersOfAttorneyForGoods
	|		ON (PowersOfAttorneyForGoods.Ref = DocumentIssuedLetterOfAuthority.Ref)
	|		LEFT JOIN Received AS Received
	|		ON (Received.Ref = DocumentIssuedLetterOfAuthority.Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentIssuedLetterOfAuthority.Ref,
	|	DocumentIssuedLetterOfAuthority.DeletionMark,
	|	PRESENTATION(DocumentIssuedLetterOfAuthority.Ref),
	|	ISNULL(Paid_.AmountOfPayments, 0),
	|	NOT Paid_.Ref IS NULL,
	|	FALSE
	|FROM
	|	Document.IssuedLetterOfAuthority AS DocumentIssuedLetterOfAuthority
	|		INNER JOIN PowerOfAttorneyForCash AS PowerOfAttorneyForCash
	|		ON (PowerOfAttorneyForCash.Ref = DocumentIssuedLetterOfAuthority.Ref)
	|		LEFT JOIN Paid_ AS Paid_
	|		ON (Paid_.Ref = DocumentIssuedLetterOfAuthority.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP PowersOfAttorneyForGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP PowerOfAttorneyForCash
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Received
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Paid_";
	
	Query.SetParameter("ReferencesArrray", ObjectsArray);
	
	TableOfPowersOfAttorney = Query.Execute().Unload();
	TableOfPowersOfAttorney.Indexes.Add("Ref");
	
	SetPrivilegedMode(False);
	
	Return TableOfPowersOfAttorney;
EndFunction

Procedure CalculatePowerOfAttorneyStatus(Object, Val ThereArePayments = False, Val AmountOfPayments = 0, Val HasGoodsReceipt = False) Export
	
	If Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash Then
		If ThereArePayments Then
			Object.DocumentPaymentsAmount = AmountOfPayments;
			If AmountOfPayments < Object.DocumentAmount Then
				Object.Status = Enums.StatusesOfAuthorizationLetters.UsedPartially;
			Else
				Object.Status = Enums.StatusesOfAuthorizationLetters.Used_3;
			EndIf;
		Else
			Object.DocumentPaymentsAmount = 0;
		EndIf;
	ElsIf Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods Then
		
		Object.HasGoodsReceipt = HasGoodsReceipt;
		If HasGoodsReceipt Then
			Object.Status = Enums.StatusesOfAuthorizationLetters.Used_3;
		EndIf;
	EndIf;
EndProcedure

Procedure CalculateStatusOfPowersOfAttorney(MethodParameters, StorageAddress) Export
	
	ErrorPatternMarkedForDeletion = NStr("vi = 'Chứng từ %1 được đánh dấu để xóa. Không thể tính toán trạng thái';
										|ru = 'Документ %1 помечен на удаление. Невозможно рассчитать статус';
										|en = 'The %1 document is marked for deletion. Cannot calculate status'; fa = 'The %1 document is marked for deletion. Cannot calculate status';
										|it = 'Il documento %1 è contrassegnato per la cancellazione. Impossibile calcolare lo stato';
										|pl = 'Dokument %1 jest zaznaczony na usunięcie. Niemożliwe jest rozliczenie statusu';
										|tr = '%1belgesi silinmek üzere işaretlendi. Durum hesaplanamıyor'");
	BlockErrorTemplate = NStr("vi = 'Không thể phong tỏa %1. %2';
								|ru = 'Не удалось заблокировать %1. %2';
								|en = 'Cannot block %1. %2'; fa = 'Cannot block %1. %2';
								|it = 'Impossibile bloccare %1. %2';
								|pl = 'Nie udało się zablokować %1. %2';
								|tr = '%1 engellenemedi. %2'");
	WriteErrorTemplate = NStr("vi = 'Không thể ghi lại %1. %2';
								|ru = 'Не удалось записать %1. %2';
								|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
								|it = 'Impossibile registrare %1. %2';
								|pl = 'Nie udało się zapisać %1. %2';
								|tr = '%1 kaydedilemedi. %2'");
	
	If MethodParameters.DocumentsArray.Count() = 0 Then
		SelectedDocuments = PowerOfAttorneyForLastMonth();
	Else
		SelectedDocuments = MethodParameters.DocumentsArray;
	EndIf;
	
	DocumentsComposition = Documents.IssuedLetterOfAuthority.CalculateStateOfPowerOfAttorney(SelectedDocuments);
	
	ProcessedItemsCount = 0;
	For Each DocumentLine In DocumentsComposition Do
		
		If DocumentLine.DeletionMark Then
			CommonClientServer.MessageToUser(
				StrTemplate(ErrorPatternMarkedForDeletion, DocumentLine.Presentation), DocumentLine.Ref);
			Continue;
		EndIf;
		
		Try
			LockDataForEdit(DocumentLine.Ref);
		Except
			ErrorText = StrTemplate(BlockErrorTemplate,
				DocumentLine.Presentation, BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, DocumentLine.Ref);
			Continue;
		EndTry;
		
		Object = DocumentLine.Ref.GetObject(); // DocumentObject.IssuedLetterOfAuthority
		
		CalculatePowerOfAttorneyStatus(Object,
			DocumentLine.ThereArePayments, DocumentLine.AmountOfPayments, DocumentLine.HasGoodsReceipt);
		
		Try
			Object.Write(DocumentWriteMode.Write);
			ProcessedItemsCount = ProcessedItemsCount + 1;
		Except
			ErrorText = StrTemplate(WriteErrorTemplate,
				DocumentLine.Presentation, BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, DocumentLine.Ref);
		EndTry;
	EndDo;
	
	PutToTempStorage(ProcessedItemsCount, StorageAddress);
EndProcedure

Function PowerOfAttorneyForLastMonth()
	
	Query = New Query();
	
	Query.Text = "SELECT ALLOWED DISTINCT
	|	LettersOfAuthority.Ref AS Ref
	|FROM
	|	Document.IssuedLetterOfAuthority AS LettersOfAuthority
	|WHERE
	|	NOT LettersOfAuthority.DeletionMark
	|	AND LettersOfAuthority.Date >= DATEADD(BEGINOFPERIOD(&CurrentDate, DAY), MONTH, -1)
	|	AND (LettersOfAuthority.Status = VALUE(Enum.StatusesOfAuthorizationLetters.Issued)
	|			OR LettersOfAuthority.Status = VALUE(Enum.StatusesOfAuthorizationLetters.UsedPartially)
	|				AND LettersOfAuthority.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash))";

	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
