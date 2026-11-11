
#Region Public

// See TMCommonUseClientServer.AnExternalUserIsAuthorized
Function ThisIsPartner() Export
	Return TMCommonUseClientServer.AnExternalUserIsAuthorized();
EndFunction

// Checks whether the user has the role of inputinformationponementurebezcontrol
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function EnterInformationAboutItemsWithoutControl(User = Undefined) Export
	Return Users.RolesAvailable("EnterInformationAboutItemsWithoutControl", User, False);
EndFunction

// Checks whether the user has the role of inputinformationpopartnerubezcontrol
// 
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function EnterInformationAboutPartnerWithoutControl(User = Undefined) Export
	Return Users.RolesAvailable("EnterInformationAboutPartnerWithoutControl", User, False);
EndFunction

// Checks whether the user has the role of adding and changing the printingobjects
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function AddEditObjectPrintSettings(User = Undefined) Export
	Return Users.RolesAvailable("AddEditObjectPrintSettings", User, False);
EndFunction

// Checks whether the user has the role of addingindividual agreementsclients
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function ModificationOfIndividualAgreements(User = Undefined) Export
	Return Users.RolesAvailable("AddEditCustomerTermsOfSales", User, False);
EndFunction

// Checks whether the user has the role of adding and changing the type of agreementsclients
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function ModificationOfModelAgreements(User = Undefined) Export
	Return Users.RolesAvailable("AddEditStandardTermsOfSalesWithCustomers", User, False);
EndFunction

// Checks whether the user has the role of recorddated verityin the final status
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function WriteIssuedAuthorizationLetterInItsFinalStatus(User = Undefined) Export
	Return Users.RolesAvailable("WriteIssuedAuthorizationLetterInItsFinalStatus", User, False);
EndFunction

// Checks if the user has the offsetting payment role
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function PaymentSettlement(User = Undefined) Export
	Return Users.RolesAvailable("PaymentSettlement", User, False);
EndFunction

// Checks if the user has the role of the offendingpartner of forbidden segments
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function SaleToPartnersIncludedInShipmentProhibitionSegments(User = Undefined) Export
	Return Users.RolesAvailable("SaleToPartnersIncludedInShipmentProhibitionSegments", User, False);
EndFunction

// Checks whether the user has the role deviationconditions of purchases
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function VarianceFromPurchaseConditions(User = Undefined) Export
	Return Users.RolesAvailable("VarianceFromPurchaseConditions", User, False);
EndFunction

// Checks whether the user has the role deviationsale conditions
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function VarianceFromSalesTermsAndConditions(User = Undefined) Export
	Return Users.RolesAvailable("VarianceFromSalesTermsAndConditions", User, False);
EndFunction

// Checks whether the user has the role deviationconditionspayment
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function VarianceFromPaymentTerms(User = Undefined) Export
	Return Users.RolesAvailable("VarianceFromPaymentTerms", User, False);
EndFunction

// Checks whether the user has the role of addingreference and accessibility to write work
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function RightToEnterWorkSchedulesOfRC(User = Undefined) Export
	Return Users.RolesAvailable("AddEditOfAccessibilityForWorkSchedule", User, False);
EndFunction

// Checks whether the user has the role of addingreference and accessibility for the Production graph
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function RightToEnterAvailabilityOfTypesOfRC(User = Undefined) Export
	Return Users.RolesAvailable("AddEditOfAccessibilityForProductionSchedule", User, False);
EndFunction

// Checks whether the user has the role of taking the wrong work
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function PutGoodsIssueNoteIntoOperation(User = Undefined) Export
	Return Users.RolesAvailable("PutGoodsIssueNoteIntoOperation", User, False);
EndFunction

// Checks whether the user has the role of authorizingcontrolling of product organizationsavremeaseance
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration(User = Undefined) Export
	Return Users.RolesAvailable("AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration", User, False);
EndFunction

// Parameters:
// 	User - InfoBaseUser
// Returns:
//  Boolean - True if the user has a role available to disable monitoring of inventory reserves for orders.
Function AllowDisablingOfTheControlOfGoodsReservesUnderOrdersForTheSessionDuration(User = Undefined) Export
	Return Users.RolesAvailable("AllowDisablingOfTheControlOfGoodsReservesUnderOrdersForTheSessionDuration", User, False);
EndFunction

// Checks whether the user has the role of authorizingcontrolleretrobonusesclientsremy session
// 
// Parameters:
// 	User - InfoBaseUser
// 	
// Returns:
//	Boolean - role availability
//
Function AllowDisablingRebatesBalanceCheckForSessionDuration(User = Undefined) Export
	
	Return Users.RolesAvailable(
		"AllowDisablingCustomerRebateBalanceCheckForSessionDuration",
		User,
		False);
	
EndFunction

// Checks whether the user has the role of implementing the overorder
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function SalesInExcessOfOrder(User = Undefined) Export
	Return Users.RolesAvailable("SalesInExcessOfOrder", User, False);
EndFunction

// Checks whether the user has the role of internal consumeresoverorder
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function InventoryConsumptionInExcessOfOrder(User = Undefined) Export
	Return Users.RolesAvailable("InventoryConsumptionInExcessOfOrder", User, False);
EndFunction


// Checks whether the user has the role of editingprovided sources of budgeting data
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function EditArbitraryBudgetingDataSources(User = Undefined) Export
	Return Users.RolesAvailable("EditArbitraryBudgetingDataSources", User, False);
EndFunction

// Checks if the user has the role of editing document viewsreferences
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function EditDocumentInventoryOwnerAttributes(User = Undefined) Export
	Return Users.RolesAvailable("EditDocumentInventoryOwnerAttributes", User, False);
EndFunction

// Checks whether the user has the role of the authorizationcommandation
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function ApproveApplicationsForBusinessTrip(User = Undefined) Export
	Return Users.RolesAvailable("ApproveApplicationsForBusinessTrip", User, False);
EndFunction

// Checks whether the user has the role of agreeing on the spending of funds
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function PaymentRequestsApproval(User = Undefined) Export
	Return Users.RolesAvailable("PaymentRequestsApproval", User, False);
EndFunction

// Checks whether the user has the role of reconciliationreferencesexternal links
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function ApproveCashTransferOrders(User = Undefined) Export
	Return Users.RolesAvailable("ApproveCashTransferOrders", User, False);
EndFunction

// Checks whether the user has the role of creating actsfilled worksorder
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function CreatingReportsOfCompletedWorkWithoutOrder(User = Undefined) Export
	Return Users.RolesAvailable("CreatingReportsOfCompletedWorkWithoutOrder", User, False);
EndFunction

// Checks whether the user has the role of creating the realizationingthe product servicesorder
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function CreateCustomerInvoicesWithoutReferenceToOrder(User = Undefined) Export
	Return Users.RolesAvailable("CreateCustomerInvoicesWithoutReferenceToOrder", User, False);
EndFunction

// Checks whether the user has the role of saving the set of printobjects by silence
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function SaveObjectPrintSettingsByDefault(User = Undefined) Export
	Return Users.RolesAvailable("SaveObjectPrintSettingsByDefault", User, False);
EndFunction

// Checks whether the user has the role of setting the value of the nomenclature without agreement
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function PriceSetupWithoutApproval(User = Undefined) Export
	Return Users.RolesAvailable("PriceSetupWithoutApproval", User, False);
EndFunction

// Checks if the user has a role assertionevision
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function PriceTypeApproval(User = Undefined) Export
	Return Users.RolesAvailable(Metadata.Roles.PriceTypeApproval.Name, User, False);
EndFunction

// Checks whether the user has the role of approving the spending of funds
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function ApprovalOfPaymentRequestsForPayment(User = Undefined) Export
	Return Users.RolesAvailable("ApprovalOfPaymentRequestsForPayment", User, False);
EndFunction

// Checks whether the user has the role of assertionreferences
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function ApprovalOfCashTransferReferencesForPayment(User = Undefined) Export
	Return Users.RolesAvailable("ApprovalOfCashTransferReferencesForPayment", User, False);
EndFunction

// Checks whether the user has the right to view and print these price tags
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function PrintPriceTagsAndLabels(User = Undefined) Export
	Return AccessRight("View", Metadata.DataProcessors.PrintPriceTagsAndLabels);
EndFunction

// Checks if the user has the right to add Partners to the Catalog
// Returns:
//	Boolean - availability of the right
Function RightToCreatePartner() Export
	Return AccessRight("Insert", Metadata.Catalogs.Partners);
EndFunction 

// Checks whether the user has the role of approving financial reports
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function ApprovalOfExpenseReports(User = Undefined) Export
	Return Users.RolesAvailable("ApprovalOfExpenseReports", User, False);
EndFunction

// Returns the names of roles with the right to add
// Parameters:
// 	MetadataObjectName - String - Name of the medical data object
// Returns:
//	Array of String - role names
Function NamesOfRolesWithRightToAdd(MetadataObjectName) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	RolesRights.Role.Name AS NameOfRole
	|FROM
	|	InformationRegister.RolesRights AS RolesRights
	|WHERE
	|	NOT RolesRights.Role.DeletionMark
	|	AND NOT RolesRights.MetadataObject.DeletionMark
	|	AND RolesRights.AddRight
	|	AND RolesRights.MetadataObject.FullName = &FullName";
	
	Query.SetParameter("FullName", MetadataObjectName);
	
	RolesArray = Query.Execute().Unload().UnloadColumn("NameOfRole");
	
	SetPrivilegedMode(False);
	
	Return RolesArray;
	
EndFunction

// Checks if the user has the allowformal role.Issue with a lower number
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function AllowRetroactiveReleaseRegistration(User = Undefined) Export
	
	Result = False;
	Result = Users.RolesAvailable("AllowRetroactiveReleaseRegistration", User, False);
	Return Result;
	
EndFunction

// Checks whether the user has the role to disable the controllertransmission productionprocessor
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function DisableProductTransferControlByTheSubcontractor(User = Undefined) Export
	Return Users.RolesAvailable("DisableProductTransferControlByTheSubcontractor", User, False);
EndFunction

// Checks whether the user has the role to disable the control of the transferingproduction to the seller
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function DisableControlOfManufacturedProductTransferToProvider(User = Undefined) Export
	Return Users.RolesAvailable("DisableControlOfManufacturedProductTransferToProvider", User, False);
EndFunction

// Checks if the user has the role of orderinternet userreferencesexternal links
// Parameters:
// 	User - InfoBaseUser
// Returns:
//	Boolean - role availability
Function InventoryConsumptionOrderWithoutApproval(User = Undefined) Export
	Return Users.RolesAvailable("InventoryConsumptionOrderWithoutApproval", User, False);
EndFunction

// Checks whether the user has the role "Approving the Purchase order"
// Parameters:
// 	User - CatalogRef.Users
// Returns:
//	Boolean - role availability
Function ApprovePurchaseRequests(User = Undefined) Export
	Return Users.RolesAvailable("ApprovePurchaseRequests", User, False);
EndFunction

// Checks whether the user has the role "Approval of the Support"
// Parameters:
// 	User - CatalogRef.Users
// Returns:
//	Boolean - role availability
Function ApproveProvisionRequests(User = Undefined) Export
	Return Users.RolesAvailable("ApproveProvisionRequests", User, False);
EndFunction

#EndRegion
