#Region Public

// Checks whether the transferred contract type is a sales contract.
//
// Parameters:
//  ContractType - EnumRef.ContractTypes - the type of contract to check.
//
// Returns:
//  Boolean - True if the contract type refers to sales contracts.
//
Function ThisIsSalesContract(ContractType) Export
	
	If ContractType = Enums.ContractTypes.WithCustomer
		Or ContractType = Enums.ContractTypes.WithConsignee
		Or ContractType = Enums.ContractTypes.TransferToCustody
		Or ContractType = Enums.ContractTypes.ReceiptForTolling2_5
		Or ContractType = Enums.ContractTypes.TransferToRental
		Or ContractType = Enums.ContractTypes.Sublease Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Checks whether the transferred contract type is a purchase agreement.
//
// Parameters:
//  ContractType - EnumRef.ContractTypes - the type of contract to check.
//
// Returns:
//  Boolean - True if the contract type refers to purchase contracts.
//
Function ThisIsPurchaseContract(ContractType) Export
	
	Return TypesOfProcurementContracts().Find(ContractType) <> Undefined;
	
EndFunction

#EndRegion

#Region EventHandlers

// Parameters:
// 	ChoiceData - ValueList
// 	Parameters - Structure:
// 		* Filter - Structure:
// 			** Ref - AnyRef, FixedArray - 
// 	StandardProcessing - Boolean
// 
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	If GetFunctionalOption("UseCustomerContracts") Then
		
		ChoiceData.Add(PredefinedValue("Enum.ContractTypes.WithCustomer"));
		
		If GetFunctionalOption("UseSalesCommission") Then
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.WithConsignee"));
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.SalesViaCommissionAgent"));
		EndIf;
		
		If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.TransferToCustody"));
		EndIf;
		
		If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.CustomerInvoiceOutsourcedSale"));
		EndIf;
		
	EndIf;
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		ChoiceData.Add(PredefinedValue("Enum.ContractTypes.ReceiptForTolling2_5"));
	EndIf;
	If GetFunctionalOption("UseContractsWithVendors") Then
		
		ChoiceData.Add(PredefinedValue("Enum.ContractTypes.WithVendor"));
		
		If GetFunctionalOption("UsePurchaseCommission") Then
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.WithConsignor"));
		EndIf;
		
		If GetFunctionalOption("UseImports") Then
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.Import"));
		EndIf;
		If GetFunctionalOption("UseImportOfGoodsFromCustomsUnion") Then
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.PurchaseEAEU"));
		EndIf;
		
		If GetFunctionalOption("UseCustodyDuringPurchase") Then
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.ReceivingForCustody"));
		EndIf;
		
	EndIf;
	If GetFunctionalOption("UseProductionByThirdParty2_5") Then
		ChoiceData.Add(PredefinedValue("Enum.ContractTypes.TransferToTolling2_5"));
		If GetFunctionalOption("UseImportOfGoodsFromCustomsUnion") Then
			ChoiceData.Add(PredefinedValue("Enum.ContractTypes.SubcontractingToTheEAEUCountries"));
		EndIf;
	EndIf;
	If GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		ChoiceData.Add(PredefinedValue("Enum.ContractTypes.TransferToRental"));
		ChoiceData.Add(PredefinedValue("Enum.ContractTypes.Sublease"));
	EndIf;
	If Parameters.Filter.Property("Ref") Then
		
		TheListOfAllowedValues = ChoiceData.Copy();
		ChoiceData.Clear();
		
		LinkSelectionValue = Parameters.Filter.Ref;
		If Not TypeOf(LinkSelectionValue) = Type("FixedArray") Then
			
			ArrayOfValuesInSelection = New Array;
			ArrayOfValuesInSelection.Add(LinkSelectionValue);
			
		Else
			ArrayOfValuesInSelection = LinkSelectionValue;
		EndIf;
		
		For Each CurValue In ArrayOfValuesInSelection Do
			
			If TheListOfAllowedValues.FindByValue(CurValue) <> Undefined Then
				ChoiceData.Add(CurValue);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(Parameters.SearchString) Then
		
		ElementIndex = -(ChoiceData.Count()-1);
		For ElementIndex = ElementIndex To 0 Do
			CurItem = ChoiceData.Get(-ElementIndex);
			If Not StrStartsWith(Lower(CurItem.Value), Lower(Parameters.SearchString)) Then
				ChoiceData.Delete(CurItem);
			EndIf;	
		EndDo;
		
	EndIf;	
	
	ChoiceData.SortByValue();

EndProcedure

#EndRegion

#Region Private

// Types of procurement Contracts.
// 
// Returns:
//  Array of EnumRef.ContractTypes - Types of Procurement Contracts
Function TypesOfProcurementContracts()
	
	ReturnValue = New Array;
	
	ReturnValue.Add(WithVendor);
	ReturnValue.Add(PurchaseEAEU);
	ReturnValue.Add(Import);
	
	ReturnValue.Add(WithConsignor);
	
	ReturnValue.Add(ReceivingForCustody);
	ReturnValue.Add(CustomerInvoiceOutsourcedSale);
	
	ReturnValue.Add(TransferToTolling2_5);
	ReturnValue.Add(SubcontractingToTheEAEUCountries);
	
	Return ReturnValue;
	
EndFunction

#EndRegion
