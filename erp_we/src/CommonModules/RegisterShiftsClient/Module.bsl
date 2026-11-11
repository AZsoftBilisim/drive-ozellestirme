
#Region Internal

// The fiscal device determines the status of the shift and checks its activity. Activity means compliance with the following conditions:
// - the cash shift is not closed no more than 24 hours have passed since the opening of the cash shift.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals - fiscal device for which you want to determine the activity shifts
//
// Returns:
//  Structure:
//    *IsOpen - Boolean - The truth - the shift is open, the lie - the shift is closed.
//    *Active - Boolean - True - the shift is open, False - the shift is closed, more than 24 hours have passed since the opening or has never been opened.
//    *CurReceiptNumber - Number - The current number of the KKT receipt.
// 
Function LastShiftStatus(FiscalDevice) Export
	
	StatusesOfCashShifts = EquipmentManagerClient.Peripherals().StatusesOfCashShifts;
	LastShiftStatus = StatusesOfCashShifts.Get(FiscalDevice);
	If LastShiftStatus = Undefined Then
		LastShiftStatus = CashRegisterShiftsServerCall.LastShiftStatus(FiscalDevice);
		StatusesOfCashShifts.Insert(FiscalDevice, LastShiftStatus);
	EndIf;
	Return LastShiftStatus;
	
EndFunction

Procedure SetStatusOfLastShift(FiscalDevice, LastShiftStatus) Export
	
	If Not ValueIsFilled(FiscalDevice) Then
		Return;
	EndIf;
	
	StatusesOfCashShifts = EquipmentManagerClient.Peripherals().StatusesOfCashShifts;
	StatusesOfCashShifts.Insert(FiscalDevice, LastShiftStatus);
	
EndProcedure



#EndRegion