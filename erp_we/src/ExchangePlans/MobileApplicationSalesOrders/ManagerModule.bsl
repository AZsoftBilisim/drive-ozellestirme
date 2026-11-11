#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns whether the exchange plan is used to organize the exchange in the service model.
//  If this option is selected, you can enable data exchange
//  using this exchange plan in the service.
//  If this option is omitted, the exchange plan will only be used 
//  for exchange in the local configuration mode.
//
// Returns:
//  Boolean - indicates the use of an exchange plan to organize an exchange in the service model.
//
Function ExchangePlanUsedInSaaS() Export
	
	Return False;
EndFunction

// Returns whether Push notifications are used.
//
// Returns:
//  Boolean - True when sending Push notifications is used.
//
Function ExchangePlanUsesSendingPushNotifications() Export
	
	ThisNode = ExchangePlans.MobileApplicationSalesOrders.ThisNode();
	Return Not Common.ObjectAttributeValue(ThisNode, "PushNotificationOption") = Enums.PushNotificationOptions.DontSend;
EndFunction

// Returns an array of selection elements that will be used in the form header.
//
// Returns:
//  Array - array of form header details.
//
Function FormHeaderDetails() Export
	
	FormHeaderDetails = New Array;
	FormHeaderDetails.Add("POSTerminal");
	FormHeaderDetails.Add("ArticleDDSAcquiring");
	
	FormHeaderDetails.Add("Supervisor_");
	
	FormHeaderDetails.Add("UsePowerOfAttorneyToRegisterPayment");
	FormHeaderDetails.Add("UseICOToRegisterPayment");
	FormHeaderDetails.Add("CashAccount");
	FormHeaderDetails.Add("ArticleDDSCash");
	
	FormHeaderDetails.Add("UseWeightCharacteristics");
	FormHeaderDetails.Add("TransmitProductImages");
	
	FormHeaderDetails.Add("DoNotDisplayBalanceWhenSelecting");
	
	Return FormHeaderDetails;
EndFunction

// Returns matches of selection elements and functional options used.
//
// Returns:
//  Array - array of matches of selection elements to functional options.
//
Function MatchingSelectionElementsToFunctionalOptions() Export
	
	Maps1 = New Array;
	
	Dependence = New Map;
	Dependence.Insert("UseProductSegments", "ProductSegment");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UsePartnersSegments", "PartnersSegment");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UseMultipleCompanies", "Organization");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UseSeveralPriceTypes", "PriceKind");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UseSeveralWarehouses", "Warehouse");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("ToUseTermsOfSales", "Terms");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UsePaymentByCards", "POSTerminal");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UsePaymentByCards", "ArticleDDSAcquiring");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UseAuthorizationLettersForInventoryReceipt", "UsePowerOfAttorneyToRegisterPayment");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UseMultipleCashAccounts", "CashAccount");
	Maps1.Add(Dependence);
	
	Dependence = New Map;
	Dependence.Insert("UseJobsToManageSalesRepresentatives", "Supervisor_");
	Maps1.Add(Dependence);
	
	Return Maps1;
EndFunction

// Returns a predefined node of the exchange plan "Mobile app" 1C:Orders".
//
// Returns:
//  ExchangePlanRef - a predefined node.
//
Function MainExchangeNode() Export
	
	MainExchangeNode = ExchangePlans.MobileApplicationSalesOrders.ThisNode();
	
	If Not ValueIsFilled(Common.ObjectAttributeValue(MainExchangeNode, "Code")) Then
		MainNodeObject = MainExchangeNode.GetObject();
		MainNodeObject.Code = "001";
		MainNodeObject.Description = NStr("vi = 'Trung tâm';
											|ru = 'Центральный';
											|en = 'Central'; fa = 'Central';
											|it = 'Centrale';
											|pl = 'Central';
											|tr = 'Merkezi'");
		MainNodeObject.Write();
	EndIf;
	Return MainExchangeNode;
EndFunction

#EndRegion

#EndIf
