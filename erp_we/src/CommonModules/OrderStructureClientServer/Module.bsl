
#Region Public

// Code of procedures and functions

#EndRegion

#Region Internal

Function ExpectEndOfOrderStructureCalculation(StatusCode, StateCodesForCalculatingOrderStructure) Export
	
	If StatusCode = StateCodesForCalculatingOrderStructure.AwaitingCalculation Then
		
		OrderStructureServerCall.StartCalculation();
		
		Return True;
		
	Else
		
		Return StatusCode = StateCodesForCalculatingOrderStructure.Calculating
			Or StatusCode = StateCodesForCalculatingOrderStructure.IsCancelled;
		
	EndIf;
	
EndFunction

Procedure DisplayStateOfStructureCalculation(Items, Protocol) Export
	
	Items.PageNotCalculated.Visible           = (Protocol.State = Protocol.StateCodes.NotCalculated);
	Items.PageCalculated.Visible             = (Protocol.State = Protocol.StateCodes.Calculated);
	Items.ThePageIsWaitingForTheCalculation.Visible        = (Protocol.State = Protocol.StateCodes.AwaitingCalculation);
	Items.CalculatingPage.Visible        = (Protocol.State = Protocol.StateCodes.Calculating);
	Items.ThePageIsCanceled.Visible            = (Protocol.State = Protocol.StateCodes.IsCancelled);
	Items.PageIsCalculatedThereAreErrors.Visible   = (Protocol.State = Protocol.StateCodes.CalculatedHasErrors);
	Items.ThePageIsNotCalculatedThereAreErrors.Visible = (Protocol.State = Protocol.StateCodes.NotCalculatedHasErrors);
	
	If Protocol.State = Protocol.StateCodes.CalculatedHasErrors Then
		
		Items.ErrorGroupForFillingInProductData.Visible = Protocol.Errors.Find(Protocol.ErrorCodes.ErrorsInFillingInProductData) <> Undefined;
		Items.GroupErrorsInSelectionOfSpecificationsInProductionOrders.Visible = Protocol.Errors.Find(Protocol.ErrorCodes.SpecificationSelectionErrors) <> Undefined;
		Items.GroupErrorsInCalculationOfRegulatorySchedule.Visible = Protocol.Errors.Find(Protocol.ErrorCodes.ErrorsInCalculationOfRegulatorySchedule) <> Undefined;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Code of procedures and functions

#EndRegion
