///////////////////////////////////////////////////////////////////////////////
// The module "Activity Directionserver" contains the procedures and functions necessary for
// the operation of the server part of the forms of invoices and orders.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region CommonFormEventHandlers

// Outdated. You must use the assignation server.Parish and Creation in the Server
// It is used in forms of documents, in procedures of the same name "Prikhteniyisozdaniinaserver".
// Initializes the Attributes of the form used for the user's interactive work. Fills out the appointment based on the
// direction of activity.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//                             of business lines.
//
Procedure OnReadCreateAtServer(Form) Export
	
	AssignmentsServer.OnReadCreateAtServer(Form, True);
	
EndProcedure

// Outdated. You must use the assignation server.Post-recording on the Server
// It is used in forms of documents, in procedures of the same name "Post-recording Server".
// Fills in the Attributes of the "Ship separately" form of the tabular part based on the fullness of the destination.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//                             of business lines.
//
Procedure AfterWriteAtServer(Form) Export
	
	AssignmentsServer.AfterWriteAtServer(Form, True);
	
EndProcedure

#EndRegion

#Region EventHandlersForElementsOnForms

// Outdated. You must use the assignation server.When changing the Assignation template in a document
// It is used in forms of documents, in procedures leading to a change in the direction of activity.
// Initializes the Attributes of the form used for the user's interactive work. Fills out the appointment based on the
// direction of activity. If necessary, updates the assignments in the tabular parts of the document, in accordance with
// the changed direction of activity.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//                             of business lines.
//
// Returns:
//  Array of FormDataCollectionItem - array of modified rows of the tabular part of the document.
//
Function WhenChangingDirectionOfActivity(Form) Export
	
	Return AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(Form, True);
	
EndFunction

// Outdated. You must use the assignation server.Set the visibility of the elements separately
// It is used in forms of documents, in procedures that lead to changing the flag on orders.
// Controls the visibility of elements.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to respond to a change in the flag for orders.
//
Procedure SetVisibilityOfElementsSeparately(Form) Export
	
	AssignmentsServer.SetVisibilityOfElementsSeparately(Form, True);
	
EndProcedure

// Outdated. You must use the assignation server.When filling in the Server specificationservers
// Used in the form of the order document to the processor when filling out the document according to the specification.
// Initializes the Attributes of the form used for the user's interactive work. Fills out the appointment based on the
// direction of activity.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//                             of business lines.
//
Procedure WhenFillingInServerSpecification(Form) Export
	
	AssignmentsServer.WhenFillingInServerSpecification(Form, True);
	
EndProcedure

// Outdated. You must use the assignation server.Set the conditional form of the flag separately
// Used in document forms. Sets the conditional design of the flag Separately..
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to set the conditional design.
//
Procedure SetConditionalAppearanceOfFlagSeparately(Form) Export
	
	AssignmentsServer.SetConditionalAppearanceOfFlagSeparately(Form, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Outdated. You must use the assignation server.Set the Label separately
// In the tabular part of the document form, sets the "Separate" flag for selected lines.
// Parameters:
//  Form - ClientApplicationForm - shape.
//  Set - Boolean - True if you need to set a flag, False if you need to reset the flag.
Procedure SetUncheckSeparately(Form, Set) Export
	
	AssignmentsServer.SetUncheckSeparately(Form, Set, True);
	
EndProcedure

#EndRegion

#Region FillType

// Fills in the "activity Direction" details in the line according to the destination data or the passed parameter
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action,
//  														   The value - Structure - activity settings.
//  CachedValues - Structure - saved values of parameters used during processing.
//  ActionParameters    - Structure, Undefined - parameters for performing this action.
//
Procedure FillInDirectionOfActivity(
			CurrentRow, StructureOfActions, CachedValues, ActionParameters = Undefined) Export

	Var LineOfBusiness;

	If ValueIsFilled(CurrentRow.Purpose) Then

		PropertiesPurpose = CachedValues.AssignmentProperties.Get(CurrentRow.Purpose);

		If PropertiesPurpose = Undefined Then

			AssignmentProperties = Catalogs.Assignments.AssignmentProperties(CurrentRow.Purpose);
			PropertiesPurpose = AssignmentProperties.Get(CurrentRow.Purpose);

			CachedValues.AssignmentProperties.Insert(CurrentRow.Purpose, PropertiesPurpose);

		EndIf;

		LineOfBusiness = PropertiesPurpose.LineOfBusiness;

	ElsIf ActionParameters <> Undefined Then

		LineOfBusiness = ActionParameters.LineOfBusiness;

	EndIf;

	CurrentRow.LineOfBusiness = LineOfBusiness;

EndProcedure

// Fills in the Attributes of the "Activity direction" in the line according to the data of the assignment or the transmitted parameter
// using the batch processing mechanism of the rows of the table parts.
//
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow.
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//  ActionParameters    - Structure, Undefined - parameters for performing this action.
//
Procedure FillInLineOfBusinessInBatch(
			CurrentRow, StructureOfActions, CachedValues, ActionParameters = Undefined) Export

	Var LineOfBusiness;

	If ValueIsFilled(CurrentRow.Purpose) Then

		PropertiesPurpose = CachedValues.AssignmentProperties.Get(CurrentRow.Purpose);

		If PropertiesPurpose = Undefined Then
			
			LineOfBusiness = BatchProcessingOfTablePartServer.DataForStringProcessing(
										"LineOfBusinessForIntendedPurpose",
										CachedValues)[0].LineOfBusiness;
			
		Else
			
			LineOfBusiness = PropertiesPurpose.LineOfBusiness;
			
		EndIf;
		
	ElsIf ActionParameters <> Undefined Then

		LineOfBusiness = ActionParameters.LineOfBusiness;

	EndIf;

	CurrentRow.LineOfBusiness = LineOfBusiness;

EndProcedure

// Fills in the direction from the agreement or agreement
//
// Parameters:
//  LineOfBusiness - CatalogRef.LinesOfBusiness - the field of activity to be filled in.
//  Terms - CatalogRef.TermsOfSale, CatalogRef.TermsOfPurchaseFromVendors - The agreement document.
//  Contract - CatalogRef.CounterpartyContracts,
//            Referenceslink.Agreement on creditdeposits,
//            Referenceslink.Lease
//            agreementsreferencesexternal links.Agreements between organizations - A document agreement.
//
Procedure FillInDefaultDirection(LineOfBusiness, Val Terms = Undefined, Val Contract = Undefined) Export
	
	If ValueIsFilled(Contract) Then
		LineOfBusiness = Common.ObjectAttributeValue(Contract, "LineOfBusiness");
	ElsIf ValueIsFilled(Terms) Then
		LineOfBusiness = Common.ObjectAttributeValue(Terms, "LineOfBusiness");
	EndIf;
	
EndProcedure

// Outdated. You must use the assignation server.Re-fill in the servicerequisits of the table part
//  Used in document forms. Fills in the Attributes of the "Ship separately" form of the tabular part based on the fullness of the destination.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//                             of business lines.
//
Procedure ReFillInServiceDetailsOfTablePart(Form) Export
	
	AssignmentsServer.ReFillInServiceDetailsOfTablePart(Form, True);
	
EndProcedure

// Adds a request to the request package to get the data needed to fill out the activity
// for the intended purpose. 
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextLineOfBusinessForIntendedPurpose(StructureOfActions, QueryDetails, CachedValues) Export
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInDirectionOfActivity", StructureOfActions, CachedValues) Then
	
		QueryText = "SELECT
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	ISNULL(CatalogAssignments.LineOfBusiness, VALUE(Catalog.Assignments.EmptyRef)) AS LineOfBusiness
			|FROM
			|	TTDataSource AS DataSource
			|		LEFT JOIN Catalog.Assignments AS CatalogAssignments
			|		ON DataSource.Purpose = CatalogAssignments.Ref";
		QueryDetails.QueriesTexts.Add(QueryText, "LineOfBusinessForIntendedPurpose");
	EndIf;
	
EndProcedure

#EndRegion

#Region AvailabilitySetting

// Set the LB editing option.
// 
// Parameters:
//  Form - ClientApplicationForm
//  AvailabilityParameters - See ParametersLBEditingCapability
//
Procedure SetLBEditingOption(Form, AvailabilityParameters) Export
	
	If Not ValueIsFilled(AvailabilityParameters.NameOfLBElement) Then
		Return;
	EndIf;
	
	If AvailabilityParameters.ThisIsOrder
		And AvailabilityParameters.OrderAsAProformaInvoice Then
		
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, AvailabilityParameters.NameOfLBElement, "ReadOnly", True);
		
	Else
		
		ContractLBHasBeenFilledIn = False;
		If ValueIsFilled(AvailabilityParameters.Contract)
			And (TypeOf(AvailabilityParameters.Contract) = Type("CatalogRef.CounterpartyContracts")
				Or TypeOf(AvailabilityParameters.Contract) = Type("CatalogRef.IntercompanyContracts")) Then
			SetPrivilegedMode(True);
			ContractLBHasBeenFilledIn = ValueIsFilled(Common.ObjectAttributeValue(AvailabilityParameters.Contract, "LineOfBusiness"));
			SetPrivilegedMode(False);
		EndIf;
		
		If AvailabilityParameters.ThisIsOrder Then
			
			ReadOnly =
				Not AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByOrders")
				And Not AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")
				And Not AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
				And Not (AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
					And Not ContractLBHasBeenFilledIn)
				And Not (AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")
					And Not ContractLBHasBeenFilledIn);
			
		ElsIf AvailabilityParameters.OrderInvoice_3 Then
			
			ReadOnly =
				Not AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
				And Not AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")
				And Not AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice");
			
		ElsIf AvailabilityParameters.IsCatalog Then
			ReadOnly = False;
		Else
			
			ReadOnly =
				AvailabilityParameters.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
					And ContractLBHasBeenFilledIn;
			
		EndIf;
		
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, AvailabilityParameters.NameOfLBElement, "ReadOnly", ReadOnly);
		
	EndIf;
	
EndProcedure

// Parameters the LB can be edited.
// 
// Returns:
//  Structure - Parameters LB Editing Capability:
// * IsCatalog - Boolean
// * ThisIsOrder - Boolean
// * OrderAsAProformaInvoice - Boolean
// * OrderInvoice_3 - Boolean
// * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts, Undefined - The Contract specified in the document.
// * ARAPObjectSettings - EnumRef.ARAPObjectSettings
// * NameOfLBElement - String
//
Function ParametersLBEditingCapability() Export
	
	AvailabilityParameters = New Structure;
	
	AvailabilityParameters.Insert("IsCatalog",      False);
	AvailabilityParameters.Insert("ThisIsOrder",           False);
	AvailabilityParameters.Insert("OrderAsAProformaInvoice",       False);
	AvailabilityParameters.Insert("OrderInvoice_3",  False);
	
	AvailabilityParameters.Insert("Contract",            Undefined);
	AvailabilityParameters.Insert("ARAPObjectSettings",    Enums.ARAPObjectSettings.EmptyRef());
	
	AvailabilityParameters.Insert("NameOfLBElement",      "LineOfBusiness");
	
	Return AvailabilityParameters;
	
EndFunction

#EndRegion

#Region Other

// Sets the conditional for the prop directionof Activity.
//
// Parameters:
//	Form - ClientApplicationForm - the form for which the conditional design is configured.
//
Procedure EstablishConditionalAppearanceOfDirectionOfActivity(Form) Export
	
	//
	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	DirectionField = Form.Items.LineOfBusiness; // FormField - 
	ItemField.Field = New DataCompositionField(DirectionField.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineOfBusinessIsMandatory");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LineOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = Form.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(DirectionField.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineOfBusinessIsMandatory");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LineOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

// Determines whether a business transaction generates revenue
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - Business transaction of a document or contract.
//
// Returns:
// 		Boolean - True, if income is generated.
//
Function EconomicOperationGeneratesIncome(BusinessOperation) Export
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentSale
		Or BusinessOperation = Enums.BusinessTransactions.RetailSaleOfGoods
		Or BusinessOperation = Enums.BusinessTransactions.ShipmentWithDeferredTransferOfTitle
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer 
		Or BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.WriteOffReportFromCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByCustodian
		//Intercompany
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany
		Or BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn 
		Or BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn
		Or BusinessOperation = Enums.BusinessTransactions.CommissionReportIntercompany
		Or BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		
		Return True;
	
	Else
	
		Return False;
	
	EndIf;

EndFunction

// Determines whether a business transaction forms an asset
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - Business transaction of a document or contract.
//
// Returns:
// 		Boolean - True if an asset is formed.
//
Function BusinessTransactionFormsAsset(BusinessOperation) Export
	
	If BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder 
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
		Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor
		Or BusinessOperation = Enums.BusinessTransactions.RegisterCCDThroughBroker
		Or BusinessOperation = Enums.BusinessTransactions.RegisterCCDUnassisted 
		Or BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5
		Or BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentReportToVendor
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost
		Or BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage
		
		Or BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand
		Or BusinessOperation = Enums.BusinessTransactions.TransferToOperation
		Or BusinessOperation = Enums.BusinessTransactions.Repair
		Or BusinessOperation = Enums.BusinessTransactions.Modernization
		Or BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5
		Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
		Or BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents
		Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromProduction
		Or BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction
		Or BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByIncomeLiabilities
		Or BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByExpencesAssets
		Or BusinessOperation = Enums.BusinessTransactions.RegistrationAtFADisposal
		Or BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation
		
		Or BusinessOperation = Type("DocumentRef.ProductionOrder2_2")
		Or BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods
		Or BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany
		//Intercompany
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany 
		Or BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn 
		Or BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn
		Or BusinessOperation = Enums.BusinessTransactions.CommissionReportIntercompany 
		
		Or BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		
		Return True;
	
	Else
	
		Return False;
	
	EndIf;

EndFunction

// Defines the order of assignment formation when recording separate requirements for orders in this area of activity.
//
// Parameters:
//  Ref - CatalogRef.LinesOfBusiness - the direction of activity that can be specified in the order.
//
// Returns:
//  Boolean - True if this line of activity will be used in the analysis of a separate
//           order need, False otherwise.
//
Function ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Ref) Export
	
	If ValueIsFilled(Ref) Then
		
		SetPrivilegedMode(True);
		Return Common.ObjectAttributeValue(Ref, "CostAccounting");
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Outdated. You must use the assignation server.The order of filling in the assignment in the document
// Designer of the structure of parameters for embedding activities in a document.
//  Returns:
//   See AssignmentsServer.ProcedureForFillingOutAssignmentsInDocument
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity() Export
	
	Return AssignmentsServer.ProcedureForFillingOutAssignmentsInDocument();
	
EndFunction

// Outdated. You must use the assignation server.Conditionsprocessing assignationstrings
// 
// Parameters:
//  ConditionTemplates - String
// 
// Returns:
//  Array of Structure - Conditions For Processing Assignments In Rows
//
Function ConditionsForProcessingAssignmentsInRows(ConditionTemplates) Export
	
	Return AssignmentsServer.ConditionsForProcessingAssignmentsInRows(ConditionTemplates);
	
EndFunction

// Outdated. You must use the assignation server.Object structureobject
// The constructor of the default structure for use in the functions
// of the description of the document form for filling out requirements related to the direction of activity of document manager modules.
//
// Returns:
//  Structure - structure with fields:
//   *IssuedByOrder - Boolean - indicates that the rows of the table parts can be made to order.
//   *ThisIsSourceOfNeed - Boolean - indicates that the document is a document of fixing a separate need (order).
//   *ThereIsVHFAppointment - Boolean - indicates that the rows of the table parts have the assignment attribute.
//   *InTSPurposeOfShipment - Boolean - indicates that in the rows of the table parts, the destination attribute is used to indicate
//                            the destination of the goods and works being shipped, and not accepted).
//   *TabSections - Structure - description of the table part of the document, used to override the general parameters set for
//                           all table parts.
//
Function ObjectStructure() Export
	
	Return AssignmentsServer.ObjectStructure();
	
EndFunction

// Outdated. You must use the assignation server.Pushing Assignment
//  Returns an assignment by activity area.
//
// Parameters:
//  LineOfBusiness - CatalogRef.LinesOfBusiness - direction of activity.
//
// Returns:
//  CatalogRef.Assignments - an appointment related to the line of business.
//
Function PushingAssignment(LineOfBusiness) Export
	
	Return AssignmentsServer.PushingAssignment(LineOfBusiness);
	
EndFunction

#EndRegion

#EndRegion