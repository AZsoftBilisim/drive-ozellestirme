#Region Public

// The event handler is called when the cashier's name is received.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals
//  AdditionalParameters - Structure
//
Procedure FuManagementFillInAdditionalParametersBeforeOpeningShift(FiscalDevice, AdditionalParameters) Export
	
	CashRegister = RetailSalesServerCall.CashDeskCashRegisterForPlugInEquipmentForCWP(FiscalDevice);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CashRegister", CashRegister);
	
EndProcedure

#EndRegion
