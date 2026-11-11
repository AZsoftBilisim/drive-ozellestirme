//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	SegmentsAreUsed = GetFunctionalOption("UsePartnersSegments");
	ContractsWithCustomersAreUsed = GetFunctionalOption("UseCustomerContracts");
	StandardAgreementsWithClientsAreUsed = GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	IndividualAgreementsWithClientsAreUsed = GetFunctionalOption("UseCustomerTermsOfSales");
	
	ChoiceData = New ValueList; // List of values from the enumerationlink.Compositions of participants of Retrobonuses
	ChoiceData.Add(TIN);
	ChoiceData.Add(Counterparties);
	ChoiceData.Add(Customers);
	
	If SegmentsAreUsed Then
		ChoiceData.Add(PartnersSegments);
	EndIf;
	
	If ContractsWithCustomersAreUsed Then
		ChoiceData.Add(Contracts);
	EndIf;
	
	If StandardAgreementsWithClientsAreUsed
	 Or IndividualAgreementsWithClientsAreUsed Then
		ChoiceData.Add(Terms1);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
