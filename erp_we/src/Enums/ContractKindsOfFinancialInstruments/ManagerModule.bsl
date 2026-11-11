#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	If GetFunctionalOption("UseLoanAndDepositContracts") Then
		ChoiceData.Add(Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
		ChoiceData.Add(Enums.ContractKindsOfFinancialInstruments.Deposit);
		ChoiceData.Add(Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing);
	EndIf;
	If NonCurrentAssets.VNAManagementIsUsed() Then
		ChoiceData.Add(Enums.ContractKindsOfFinancialInstruments.Lease);
	EndIf;
EndProcedure

#EndRegion

#EndIf

