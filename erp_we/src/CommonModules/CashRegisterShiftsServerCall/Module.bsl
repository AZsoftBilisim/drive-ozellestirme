
#Region Public

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
	
	Return RegisterShifts.LastShiftStatus(FiscalDevice);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Outdated: Cash changes should be used.The shift is active.
// Checks whether the cash shift is active. Activity means compliance with the following conditions:
// the cash shift is not closed, no more than 24 hours have passed since the opening of the cash shift.
//
// Parameters:
//  CashRegisterShift - DocumentRef.CashRegisterShift - Cash shift that needs to be checked for activity
//
// Returns:
//  Boolean - shift activity
Function ShiftIsActive(CashRegisterShift) Export
	
	Return RegisterShifts.ShiftIsActive(CashRegisterShift);
	
EndFunction

// Outdated: Cash changes should be used.The shift is closed.
// Checks whether the cash shift is closed.
//
// Parameters:
//  CashRegisterShift - DocumentRef.CashRegisterShift - Cash shift that needs to be checked for activity
//
// Returns:
//  Boolean - True - the shift is closed, False - the shift is not closed
Function ShiftClosed(CashRegisterShift) Export
	
	Return RegisterShifts.ShiftClosed(CashRegisterShift);
	
EndFunction

// Outdated: Cash changes should be used.Description of the cash exchange.
// Gets Attributes of the cash shift
//
// Parameters:
//  CashRegisterShift - DocumentRef.CashRegisterShift - Cash shift that needs to be checked for activity
//
// Returns:
//  Structure - Attributes of the cash shift. Contains the following Attributes:
//    *CashRegisterShift - DocumentRef.CashRegisterShift - Link to the cash shift
//    *FiscalDevice - CatalogRef.Peripherals - link to the device on which the shift is open
//    *CashRegisterShiftStart - Date - shift opening date
//    *CashRegisterShiftEnd - Date - closing date of the shift (if the shift was closed)
//    *ExpirationDate_1 - Date - on which the validity period of the shift ends (opening date + 24 hours)
//    *Organization - DefinedType.CompanyCEL - the organization specified in the Cash Exchange document
//    *Status - EnumRef.CashRegisterShiftStatuses - the status of the cash shift.
Function DescriptionOfCashShift(CashRegisterShift) Export
	
	Return RegisterShifts.DescriptionOfCashShift(CashRegisterShift);
	
EndFunction

// Outdated: Cash changes should be used.The latest change is closed.
// The fiscal device determines the last shift and checks whether it is closed.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals - fiscal device to determine whether a shift is closed
//
// Returns:
//  Boolean - True - the shift is closed or has never been opened, False - the shift is not closed
Function LastShiftClosed(FiscalDevice) Export
	
	Return RegisterShifts.LastShiftClosed(FiscalDevice);
	
EndFunction

// Outdated: Cash changes should be used.Description of the last cash exchange.
// According to the fiscal device, it determines the last shift and receives its Attributes.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals - fiscal device for which you want to determine the activity of the shift.
//
// Returns:
//  Structure - Attributes Of the cash shift, Undefined - if no shift was opened. Contains the following Attributes:
//    *CashRegisterShift - DocumentRef.CashRegisterShift - Link to the cash shift
//    *FiscalDevice - CatalogRef.Peripherals - link to the device on which the shift is open
//    *CashRegisterShiftStart - Date - shift opening date
//    *CashRegisterShiftEnd - Date - closing date of the shift (if the shift was closed)
//    *ExpirationDate_1 - Date - on which the validity period of the shift ends (opening date + 24 hours)
//    *Organization - DefinedType.CompanyCEL - the organization specified in the Cash Exchange document.
//    *Status - EnumRef.CashRegisterShiftStatuses - the status of the cash shift.
Function DescriptionOfLastCashShift(FiscalDevice) Export
	
	Return RegisterShifts.DescriptionOfLastCashShift(FiscalDevice);
	
EndFunction

// Outdated: Cash changes should be used.Novayakassovayasmen.
// Create a new cash shift.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals
//  CommandParameters - Structure
//
// Returns:
//  DocumentRef.CashRegisterShift
//
Function NewCashRegisterShift(FiscalDevice, CommandParameters) Export
	
	Return RegisterShifts.NewCashRegisterShift(FiscalDevice, CommandParameters);
	
EndFunction

// Outdated: Cash changes should be used.Close the cash shift.
// Close a previously opened cash shift.
//
// Parameters:
//  CommandParameters - Structure
//   * Cash Exchange - Document link.Cash Exchange
//
Procedure CloseRegisterShift(CommandParameters) Export
	
	RegisterShifts.CloseRegisterShift(CommandParameters);
	
EndProcedure

#EndRegion

#EndRegion