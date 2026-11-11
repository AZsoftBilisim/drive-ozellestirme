
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ThereIsPaymentBasis = TypeOf(Parameters.DocumentRef) = Type("DocumentRef.BankAccountReceiptNote")
							Or TypeOf(Parameters.DocumentRef) = Type("DocumentRef.CashAccountReceiptNote")
							Or TypeOf(Parameters.DocumentRef) = Type("DocumentRef.PaymentCardTransaction");
	
	FinancialAccountingGroup  = Parameters.FinancialAccountingGroup;
	Contract                 = Parameters.Contract;
	LineOfBusiness = Parameters.LineOfBusiness;
	
	If Parameters.Property("Department") Then
		Department           = Parameters.Department;
	EndIf;
	
	If Not ThereIsPaymentBasis Then
		Items.Department.Visible = False;
		Items.PageGroupDiscrepanciesDivision.Visible = False;
	EndIf;
	
	Organization             = Parameters.Organization;
	Counterparty              = Parameters.Counterparty;
	BusinessOperation   = Parameters.BusinessOperation;
	DocumentRef          = Parameters.DocumentRef;
	VATTaxation      = Parameters.VATTaxation;
	
	For Each ChoiceItem In Parameters.ListOfVATTaxes Do
		Items.VATTaxation.ChoiceList.Add(ChoiceItem.Value, ChoiceItem.Presentation);
	EndDo;
	
	PaymentDecryptionVault = GetFromTempStorage(Parameters.AddressInTempStorage);
	
	For Each StorageTableRow In PaymentDecryptionVault Do
		FillPropertyValues(ARAPDetails.Add(),StorageTableRow);
	EndDo;
	
	IntercompanyBusinessTransaction = ARAPAccountingServer.IntercompanyBusinessTransaction(BusinessOperation);
	
	UpdateForDiscrepancies();
	
	SetPropertiesOfContractInputField();
	CashServer.SetParametersForSelectingDirectionOfActivity(ThisObject, Items.LineOfBusiness);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("FinancialAccountingGroup",  FinancialAccountingGroup);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("Contract",                 Contract);
	AttributesStructure1.Insert("Department",           Department);
	AttributesStructure1.Insert("VATTaxation",      VATTaxation);
	AttributesStructure1.Insert("Modified",      Modified);
	
	Close(AttributesStructure1);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Organization);
	FilterStructure1.Insert("DeletionMark", False);
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	
	If IntercompanyBusinessTransaction Then
		If  BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany") Or
			BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany") Then
			FilterStructure1.Organization = Counterparty;
			FilterStructure1.Insert("CompanyRecipient", Organization);
		Else
			FilterStructure1.Insert("CompanyRecipient", Counterparty);
		EndIf;
		StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
		OpenForm("Catalog.IntercompanyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item,)
	Else
		FilterStructure1.Insert("Counterparty", Counterparty);
		
		If FinancesClient.TheseAreSettlementsWithCustomers(BusinessOperation) Then
			StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithClient());
		Else
			StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithSupplier());
		EndIf;
		
		StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
			OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item,)
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	AgreementWhenModifiedOnServer();
	UpdateForDiscrepancies();
EndProcedure

&AtClient
Procedure FinancialAccountingGroupOnChange(Item)
	UpdateForDiscrepancies();
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	UpdateForDiscrepancies();
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	UpdateForDiscrepancies();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetPropertiesOfContractInputField()
	
	UseIntercompanyContracts = GetFunctionalOption("UseIntercompanyContracts");
	UseCustomerContracts         = GetFunctionalOption("UseCustomerContracts");
	UseContractsWithVendors      = GetFunctionalOption("UseContractsWithVendors");
	
	If IntercompanyBusinessTransaction And UseIntercompanyContracts 
		Or ARAPAccountingServer.BusinessTransactionWithClient(BusinessOperation) And UseCustomerContracts
		Or ARAPAccountingServer.BusinessTransactionWithSupplier(BusinessOperation) And UseContractsWithVendors Then
		Items.Contract.Visible = True;
	Else
		Items.Contract.Visible = False;
		Return;
	EndIf;
	
	TypesArray = New Array;
	
	If Not ValueIsFilled(Contract) Then
		If TypeOf(Counterparty) = Type("CatalogRef.Companies") Then
			Contract = PredefinedValue("Catalog.IntercompanyContracts.EmptyRef");
			TypesArray.Add(Type("CatalogRef.IntercompanyContracts"));
		Else
			Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
			TypesArray.Add(Type("CatalogRef.CounterpartyContracts"));
		EndIf;
	EndIf;
	
	Items.Contract.TypeRestriction = New TypeDescription(TypesArray);
	
EndProcedure

&AtServer
Procedure UpdateForDiscrepancies()
	
	If Not ThereIsPaymentBasis Then
		Return;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("FinancialAccountingGroup  ", FinancialAccountingGroup);
	AttributesStructure1.Insert("Contract                 ", Contract);
	AttributesStructure1.Insert("LineOfBusiness ", LineOfBusiness);
	AttributesStructure1.Insert("Department           ", Department);
	AttributesStructure1.Insert("DocumentRef          ", DocumentRef);
	
	UnallocatedPaymentDetails = CashServer.UnallocatedPaymentDetails(ARAPDetails, AttributesStructure1);
	
	If UnallocatedPaymentDetails.Count() > 0 Then
		For Each Item In NamesOfUndistributedPaymentDetails() Do
			ValueTable = UnallocatedPaymentDetails.Copy(,Item.Key);
			ValueTable.GroupBy(Item.Key);
			ArrayOfValues = ValueTable.UnloadColumn(Item.Key);
			If ArrayOfValues.Count() > 1 Then
				Items[Item.Value.Group].CurrentPage = Items[Item.Value.PageDiscrepanciesExist];
			Else
				Items[Item.Value.Group].CurrentPage = Items[Item.Value.PageNoDiscrepancies];
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function NamesOfUndistributedPaymentDetails()
	
	Structure = New Structure();
	Structure.Insert("FinancialAccountingGroup", New Structure("Group,PageDiscrepanciesExist,PageNoDiscrepancies",
		Items.DiscrepancyPageGroupFinancialAccountingGroup.Name,
		Items.PageThereAreDiscrepanciesFinancialAccountingGroup.Name,
		Items.PageNoDiscrepanciesTheGroupFinancialAccounting.Name));
	Structure.Insert("Contract", New Structure("Group,PageDiscrepanciesExist,PageNoDiscrepancies",
		Items.PageGroupDiscrepanciesAgreement.Name,
		Items.PageThereAreDiscrepanciesContract.Name,
		Items.PageNoDiscrepanciesContract.Name));
	Structure.Insert("LineOfBusiness", New Structure("Group,PageDiscrepanciesExist,PageNoDiscrepancies",
		Items.PageGroupDiscrepanciesBusinessDirection.Name,
		Items.PageThereAreDiscrepanciesBusinessDirection.Name,
		Items.PageNoDiscrepanciesBusinessDirection.Name));
	Structure.Insert("Department", New Structure("Group,PageDiscrepanciesExist,PageNoDiscrepancies",
		Items.PageGroupDiscrepanciesDivision.Name,
		Items.PageThereAreDiscrepancies.Name,
		Items.PageNoDiscrepanciesDivision.Name));
	
	Return Structure;
EndFunction

&AtServer
Procedure AgreementWhenModifiedOnServer()

	If Not ValueIsFilled(Contract) Then
		Return;
	EndIf;

	If TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts") Then
		AttributesValues = Common.ObjectAttributesValues(Contract, "FinancialAccountingGroup, LineOfBusiness");
	Else
		AttributesValues = Common.ObjectAttributesValues(Contract, "LineOfBusiness");
	EndIf;

	If CommonClientServer.HasAttributeOrObjectProperty(AttributesValues, "FinancialAccountingGroup") Then
		FinancialAccountingGroup = AttributesValues.FinancialAccountingGroup;
	EndIf;

	LineOfBusiness = CashServer.LineOfBusiness(
		BusinessOperation,
		AttributesValues.LineOfBusiness);

EndProcedure

#EndRegion
