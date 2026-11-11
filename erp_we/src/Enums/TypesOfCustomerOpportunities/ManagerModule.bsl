#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

Function TypeOfTransactionIsAvailableByFunctionalOptions(SalesOpportunityType)  Export
	
	If SalesOpportunityType = Enums.TypesOfCustomerOpportunities.StandardSale Then
		
		If GetFunctionalOption("UseEmailClient")
			And GetFunctionalOption("UseSalesOrders")
			And GetFunctionalOption("UseBusinessProcessesAndTasks") Then
			
			Return True;
			
		Else
			
			Return False;
			
		EndIf;
		
	Else
		Return True;
	EndIf;
	
	
EndFunction

#EndRegion

#EndIf