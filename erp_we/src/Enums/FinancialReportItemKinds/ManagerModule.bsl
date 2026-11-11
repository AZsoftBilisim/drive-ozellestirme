#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Caches the enumeration in the structure.
//
// Returns:
// 	 Structure - all values in the structure
//		Key - Name value
//		Value is a reference to the enumeration value.
//
Function Cache() Export
	
	ThisLink = Enums.FinancialReportItemKinds;
	ThisMetadata = Metadata.Enums.FinancialReportItemKinds;
	Cache = New Structure;
	For Each Value In ThisMetadata.EnumValues Do
		Cache.Insert(Value.Name,ThisLink[Value.Name]);
	EndDo;
	Return Cache;
	
EndFunction

// Returns the types of elements that can be sources of periods
//
// Returns:
//	Array - enumeration elements
//		* Link enumeration.Types of elements of the financial report
//
Function TypesOfSourceAndDimensionElements() Export
	TypesOfDataSourceElements = New Array;
	
	TypesOfDataSourceElements.Add(AllBudgetFlowItems);
	TypesOfDataSourceElements.Add(AllBudgetBalanceItems);
	TypesOfDataSourceElements.Add(BudgetFlowItem);
	TypesOfDataSourceElements.Add(BudgetBalanceItem);
	
	Return TypesOfDataSourceElements;
EndFunction

// Returns the types of elements that can be sources of periods
//
// Returns:
//	Array - enumeration elements
//		* Link enumeration.Types of elements of the financial report
//
Function TypesOfDataSourceElements() Export
	TypesOfDataSourceElements = TypesOfSourceAndDimensionElements();
	
	TypesOfDataSourceElements.Add(NonFinancialItem);
	TypesOfDataSourceElements.Add(EditedValue);
	
	Return TypesOfDataSourceElements;
EndFunction

#EndRegion

#EndIf