#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns an array of types of values related to the operations of the VAT agent.
// Parameters:
//     IncludingCommissionTransactions - Boolean - indicates whether it should be included in the returned array
//                                            operations of realization of values of a non-resident committee.
//     IncludingReverseAccrual   - Boolean - indicates whether it should be included in the returned array
//                                            operations of sale of goods item 8 of Article 161 of the Tax Code.
// Returns: 
//     Array - an array of values of the type of enumeration link.Types of values.
Function ArrayOfValueTypesTaxAgent(
		IncludingCommissionTransactions = True, IncludingReverseAccrual = False) Export
	
	AssetKinds = New Array;
	AssetKinds.Add(Enums.AssetKinds.TaxAgentLease);
	AssetKinds.Add(Enums.AssetKinds.TaxAgentAliens);
	AssetKinds.Add(Enums.AssetKinds.TaxAgentPropertySale);
	AssetKinds.Add(Enums.AssetKinds.TaxAgentElectronicServices);
	
	If IncludingCommissionTransactions Then
		AssetKinds.Add(Enums.AssetKinds.TaxAgentConsignor);
	EndIf;
	
	If IncludingReverseAccrual Then
		CommonClientServer.SupplementArray(
			AssetKinds,
			ArrayOfTypesOfValueTaxAgentSaleOfGoods());
	EndIf;
	
	Return AssetKinds;
	
EndFunction

// Returns an array of types of values related to the operations of the tax agent when purchasing goods
// specified in clause 8 of article 161 of the tax code of the Russian Federation.
// Returns: 
//     Array - an array of values of the type of enumeration link.Types of values.
Function ArrayOfTypesOfValueTaxAgentSaleOfGoods() Export
	
	AssetKinds = New Array;
	AssetKinds.Add(Enums.AssetKinds.PrepaymentsToVendorTaxAgent);
	AssetKinds.Add(Enums.AssetKinds.PrepaymentsFromCustomerTaxAgent);
	AssetKinds.Add(Enums.AssetKinds.RefundPrepaymentsFromCustomerTaxAgent);
	AssetKinds.Add(Enums.AssetKinds.GoodsTaxAgent);
	
	Return AssetKinds;
	
EndFunction

// Returns an array of types of values related to services and add-ons. expenses.
//
// Returns: 
//     Array - an array of values of the type of enumeration link.Types of values.
//
Function ArrayOfTypesOfValueOfServicesForCostAccounting() Export
	
	AssetKinds = New Array;
	AssetKinds.Add(Enums.AssetKinds.OtherWorksAndServices);
	AssetKinds.Add(Enums.AssetKinds.DigitalServices);
	
	Return AssetKinds;
	
EndFunction

#EndRegion

#EndIf