////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the TMC subsystem in operation.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure ProcessingOfReceivingDataOnSelectionOfBatchOfGoodsInOperation(ChoiceData, Parameters, StandardProcessing) Export
	
	If Not Parameters.Property("SelectionRestriction") 
		Or Not Parameters.SelectionRestriction Then
		Return;
	EndIf;
		
	StandardProcessing = False;
	
	ReturnStructureWhenSelecting = False;
	If Parameters.Property("ReturnStructureWhenSelecting") Then
		ReturnStructureWhenSelecting = Parameters.ReturnStructureWhenSelecting;
	EndIf;
	
	ChoiceParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation();
	FillPropertyValues(ChoiceParameters, Parameters);

	QueryDetails = InventoryInOperationClientServer.DescriptionOfRequestToSelectBatchOfGoodsAndMaterials(ChoiceParameters);
	
	Query = New Query(QueryDetails.QueryText);
	For Each ParameterDetails In QueryDetails.QueryOptions Do
		Query.SetParameter(ParameterDetails.Key, ParameterDetails.Value);
	EndDo;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ChoiceData = New ValueList;

	While Selection.Next() Do
		
		Presentation = TMCommonUse.PresentationOfSearchResultsByString(Selection.LotPresentation, Parameters.SearchString);
		
		If ReturnStructureWhenSelecting Then
			
			ValueSelected = InventoryInOperationClientServer.NewSelectionValue();
			FillPropertyValues(ValueSelected, Selection);
			
			ChoiceData.Add(ValueSelected, Presentation);
			
		Else
			ChoiceData.Add(Selection.Lot, Presentation);
		EndIf;
	
	EndDo;
	
EndProcedure

// Fills in the selection list when auto-selecting by inventory number.
// 
// Parameters:
//  PickingParameters - See InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation.
//  ChoiceData - ValueList - Selection data.
//
Procedure FillInSelectionDataByInventoryNumber(PickingParameters, ChoiceData) Export
	
	QueryDetails = InventoryInOperationClientServer.DescriptionOfRequestToSelectBatchOfGoodsAndMaterials(PickingParameters);
	
	Query = New Query(QueryDetails.QueryText);
	For Each ParameterDetails In QueryDetails.QueryOptions Do
		Query.SetParameter(ParameterDetails.Key, ParameterDetails.Value);
	EndDo;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
	
		ValueSelected = InventoryInOperationClientServer.NewSelectionValue();
		FillPropertyValues(ValueSelected, Selection);
		
		Presentation = TMCommonUse.PresentationOfSearchResultsByString(Selection.AssetID, PickingParameters.InventoryNumberContains);
		
		ChoiceData.Add(ValueSelected, Presentation);
	
	EndDo;
	
EndProcedure

#EndRegion
