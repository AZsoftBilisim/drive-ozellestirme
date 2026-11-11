#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Returns whether the exchange plan is used to organize the exchange in the service model.
//  If this option is selected, you can enable data exchange
//  using this exchange plan in the service.
//  If this option is omitted, the exchange plan will only be used 
//  for exchange in the local configuration mode.
//
// Returns:
//  Boolean - an indication of the use of the exchange plan in the service model.
//
Function ExchangePlanUsedInSaaS() Export
	
	Return False;
	
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

// Sets the code for the mobile app exchange plan node corresponding to this is.
// Called when the IB is initially filled in.
//
Procedure InitialFillingOfNodeCodeOfThisIB() Export
	
	Node = ExchangePlans.SalesRepresentativeMobileApplication.ThisNode();
	
	If ValueIsFilled(Node) Then

		NodeCode = Common.ObjectAttributeValue(Node, "Code");

		If Not ValueIsFilled(NodeCode) Then
			NodeObject = Node.GetObject();
			NodeObject.Code = 0;
			NodeObject.Write();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
