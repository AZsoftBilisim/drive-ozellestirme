
#Region Private

#Region DiscrepancyCertificate

Procedure FillInOrderAndWarehouseInLine(RowOfProductsTable, BasisDocuments, ThisIsActOfDivergenceAfterShipment) Export
	
	NamesOfActDetails = DiscrepanciesClientServer.NamesOfDetailsDependingOnTypeOfAct(ThisIsActOfDivergenceAfterShipment);

	FoundRows = BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", RowOfProductsTable[NamesOfActDetails.Basis]));
	If FoundRows.Count() = 0 Then
		Return;
	EndIf;
	
	FoundRow = FoundRows[0];
	
	If Not ValueIsFilled(RowOfProductsTable[NamesOfActDetails.OrderDocument]) Then
		If FoundRow.BasisOrders.Count() = 1 Then
			RowOfProductsTable[NamesOfActDetails.OrderDocument] = FoundRow.BasisOrders.Get(0).Value;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(RowOfProductsTable.Warehouse) Then
		If FoundRow.BasisWarehouses.Count() = 1 Then
			RowOfProductsTable.Warehouse = FoundRow.BasisWarehouses.Get(0).Value;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(RowOfProductsTable.Purpose) Then
		RowOfProductsTable.Purpose = FoundRow.Purpose;
	EndIf;

EndProcedure

// Adds a string of actions above the table part row actions required when changing the number of packages
// 
// Parameters:
// 	StructureOfActions - Structure - structure of actions performed on a row in the table part.
// 	Object            - FormDataStructure,DocumentObject.DiscrepancyReportFollowingShipment - a document that changes the number of packages.
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object) Export
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	StructureOfActions.Insert("RecalculateAmountOfDiscrepancy");
	If TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	Else
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	EndIf;
	
EndProcedure

Procedure FillInDocumentBaseInLine(RowOfProductsTable, BasisDocuments, ThisIsActOfDivergenceAfterShipment) Export
	
	NamesOfActDetails = DiscrepanciesClientServer.NamesOfDetailsDependingOnTypeOfAct(ThisIsActOfDivergenceAfterShipment);

	If Not RowOfProductsTable[NamesOfActDetails.FilledUsingBaseDocument] And Not ValueIsFilled(RowOfProductsTable[NamesOfActDetails.Basis]) Then
		If BasisDocuments.Count() = 1 Then
			RowOfProductsTable[NamesOfActDetails.Basis] = BasisDocuments[0].SaleOfGoodsAndServices;
			SetDocumentBasedOnOrderAttribute(RowOfProductsTable, BasisDocuments[0], ThisIsActOfDivergenceAfterShipment);
			FillInOrderAndWarehouseInLine(RowOfProductsTable, BasisDocuments, ThisIsActOfDivergenceAfterShipment);
		EndIf;
	EndIf;

EndProcedure

Procedure SetDocumentBasedOnOrderAttribute(RowOfProductsTable, StringFoundationDocuments, ThisIsActOfDivergenceAfterShipment) Export
	
	NamesOfActDetails = DiscrepanciesClientServer.NamesOfDetailsDependingOnTypeOfAct(ThisIsActOfDivergenceAfterShipment);
	
	RowOfProductsTable[NamesOfActDetails.BasisByOrders] = (StringFoundationDocuments.BasisOrders.Count() > 0);
	
EndProcedure

#EndRegion

#Region Other

Procedure SetListSelectionByContactPerson(Form) Export

	CommonClientServer.SetDynamicListFilterItem(
	                                Form.List, "ContactPerson", Form.ContactPersonFilter,
	                                DataCompositionComparisonType.Equal,, ValueIsFilled(Form.ContactPersonFilter));

EndProcedure

// The procedure calculates the Commission fee.
//
// Parameters:
//  Object  - FormDataStructure - the document for which the remuneration is calculated.
//
Procedure CalculateRewardAmount(Object) Export
	
	For Each RowOfGoods In Object.Goods Do
		
		If Object.CommissionFeeCalculationMethod = 
			   PredefinedValue("Enum.CommissionFeeCalculationMethods.PercentageOfDifferenceBetweenSaleAmountAndConsignorAmount") Then
			RowOfGoods.CommissionAmount = (RowOfGoods.SalesAmount - RowOfGoods.AmountIncludingVAT) * Object.RemunerationPercentage / 100;
			
		ElsIf Object.CommissionFeeCalculationMethod = 
			   PredefinedValue("Enum.CommissionFeeCalculationMethods.SaleShare") Then
			RowOfGoods.CommissionAmount = RowOfGoods.SalesAmount * Object.RemunerationPercentage / 100;
			
		Else
			RowOfGoods.CommissionAmount = 0;
			
		EndIf;
		
	EndDo;
	
	Object.CommissionAmount = Object.Goods.Total("CommissionAmount");
	
	VATAmount = PriceManagementSystemClientServer.CalculateVATAmount(Object.CommissionAmount, Object.VATRateOfRemuneration);
	Object.AmountVATRemuneration = Round(VATAmount, 2, RoundMode.Round15as20);
	
EndProcedure

// receives the business transaction of the Contract for the business transaction of the refund request.
//
// Parameters:
//  BusinessOperation  - EnumRef.BusinessTransactions - refund request operation.
//
// Returns:
//   EnumRef.BusinessTransactions - contract operation.
//
Function ContractBusinessTransaction(BusinessOperation) Export
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromRetailCustomer") Then
		Return PredefinedValue("Enum.BusinessTransactions.RetailSaleOfGoods");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsFromCustomer") Then
		Return PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then
		Return PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
		Return PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	Else
		Return PredefinedValue("Enum.BusinessTransactions.EmptyRef");
	EndIf;
	
EndFunction

// Receives the business transaction of the agreement on the business transaction of the document application for the return and return of goods from the client.
//
// Parameters:
//  BusinessOperation  - EnumRef.BusinessTransactions - business operation of the document.
//
// Returns:
//   EnumRef.BusinessTransactions - agreement operation.
//
Function BusinessTransactionFromAgreement(BusinessOperation) Export
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromRetailCustomer") Then
		Return PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsFromCustomer") Then
		Return PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent") Then
		Return PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
		Return PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	Else
		Return PredefinedValue("Enum.BusinessTransactions.EmptyRef");
	EndIf;
	
EndFunction

// Adds general actions for the regular form and the self-service form of the Customer's Return Request document.
//
// Parameters:
//  StructureOfActions  - Structure - structure to which actions are added
//  Object  - DocumentObject.RequestForReturnOfGoodsFromCustomer - the document in which the actions are performed.
//
Procedure AddReturnItemsToActionStructureWhenChangingNumberOfPackagesMain(StructureOfActions, Object) Export
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

// Adds actions when changing the number of packages for the regular form and the self-service form of the Commission Agent's Report document.
//
// Parameters:
//  StructureOfActions  - Structure - structure to which actions are added
//  Object  - DocumentObject.ConsignmentReportFromCustomer - the document in which the actions are performed.
//
Procedure AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object) Export
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateSaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	StructureOfActions.Insert("RecalculateNumberOfPackagesFactByPackages");
	
EndProcedure

// Sets the availability of the form elements of the "Partners" directory element related to the display of contact person data.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form in which actions are performed
//
Procedure AvailabilityManagementContactPersonSGroupNewAssistant(Form) Export
	
	ItemArray = New Array;
	ItemArray.Add("LastNameKL");
	ItemArray.Add("KLName");
	ItemArray.Add("PatronymicKL");
	ItemArray.Add("Role");
	ItemArray.Add("PhoneNumberKL");
	ItemArray.Add("EPCLAddress");
	ItemArray.Add("MobilePhoneKL");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items, ItemArray, "Enabled",
		Form.SpecifyTheContactPersonSDetails);
	
EndProcedure

// Manages the form pages of the "Partners" directory elements responsible for displaying information about the counterparty's registration data.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form in which actions are performed
// 	LegalEntityIndividual - EnumRef.LegalEntityIndividual - 
//
Procedure ManagingPagesOfLegalEntitiesWhenChangesOccur(Form, LegalEntityIndividual) Export
	
	If LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Person") Then
		Form.Items.PagesFullNameCompanyIndividual.CurrentPage = Form.Items.PageNameFullPrivatePerson;
	Else
		Form.Items.PagesFullNameCompanyIndividual.CurrentPage = Form.Items.PageFullNameCompany;
	EndIf;
	
	FloorShapeElement          = Form.Items.Gender; // FormField
	FormElementDateOfBirth = Form.Items.BirthDate; // FormField 
	
	FloorShapeElement.Enabled          = (LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Person"));
	FormElementDateOfBirth.Enabled = (LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Person"));

EndProcedure

#EndRegion

#EndRegion
