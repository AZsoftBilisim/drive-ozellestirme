// @strict-types

#Region Internal

// Returns:
//  See ContactsManager.AddressParameters
//
Function AddressParameters() Export
	
	Return ContactsManager.AddressParameters();
	
EndFunction

// Returns:
//  See GoodsDelivery.CheckPossibilityOfSwitchingToDelivery25
//
Function CheckPossibilityOfSwitchingToDelivery25() Export
	
	Return GoodsDelivery.CheckPossibilityOfSwitchingToDelivery25();
	
EndFunction

// Returns:
//  See GoodsDelivery.DataForTransportationTasksWithoutDeliveryMark
//
Function DataForTransportationTasksWithoutDeliveryMark() Export
	
	Return GoodsDelivery.DataForTransportationTasksWithoutDeliveryMark();
	
EndFunction

#Region Delivery20

// Parameters:
//  Address - String 
// 
// Returns:
//  Arbitrary, Undefined -
//
Function GetDeleteFromTempStorage(Address) Export
	
	Return GoodsDelivery.GetDeleteFromTempStorage(Address);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Server handler for the event processingreceiving data From the transport directory selection.
//
Procedure VehiclesProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	SearchString = Parameters.SearchString; // String
	
	If ValueIsFilled(SearchString) Then
		
		ChoiceData = New ValueList;
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	Vehicles.Ref AS Value,
		|	PRESENTATION(Vehicles.Ref) AS Presentation
		|FROM
		|	Catalog.Vehicles AS Vehicles
		|WHERE
		|	Vehicles.Code LIKE &Text
		|
		|ORDER BY
		|	Description";
		
		Query.SetParameter("Text", "%" + TrimAll(SearchString) + "%");
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			ChoiceData.Add(Selection.Value, Selection.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion
