////////////////////////////////////////////////////////////////////////////////
// NSI of production: Redefined procedures of the product data management subsystem
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region AutoSelectSpecifications

Procedure SourceOfAvailableSpecifications(QueryOptions, BOMSelectionParameters) Export
	
	If ValueIsFilled(QueryOptions.SourceOfAvailableSpecifications) Then
		Return;
	EndIf;
	
	//
	
EndProcedure

Procedure SourceOfAvailableSpecificationsApplicationOfProductsInProduction(QueryOptions, BOMSelectionParameters) Export
	
	If ValueIsFilled(QueryOptions.SourceOfAvailableSpecifications) Then
		Return;
	EndIf;
	
	//
	
EndProcedure

#EndRegion

#EndRegion