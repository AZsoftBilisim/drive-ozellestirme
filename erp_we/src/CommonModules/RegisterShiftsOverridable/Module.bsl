#Region Public

// The event handler is called on the server when the cash shift number is set.
//
// Parameters:
//	Object - DocumentRef.CashRegisterShift - The value that is used as the basis for filling in.
//	StandardProcessing - Boolean - indicates whether standard processing is being performed,
//	Prefix - String - prefix to be used for generating the number
//
Procedure OnSetNewNumber(Object, StandardProcessing, Prefix) Export
	
EndProcedure

// The event handler is called on the server when it is necessary to check the correctness of filling in the cash shift.
//
// Parameters:
//  Object - DocumentRef.CashRegisterShift - The value that is used as the basis for filling in.
//  Cancel - Boolean
//  CheckedAttributes - Array - Bank details to be checked for
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
EndProcedure

// The event handler is called on the server when you enter the document cash change based on.
//
// Parameters:
//  Object - DocumentObject.CashRegisterShift - The value that is used as the basis for filling in.
//  FillingData - Arbitrary - The value that is used as the basis for filling in,
//  FillingText - String, Undefined - Text used to fill in the document
//  StandardProcessing - Boolean
//
Procedure Filling(Object, FillingData, FillingText, StandardProcessing) Export
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("CashRegister") Then
		
		CashRegisterDetails = Catalogs.CashRegisters.CashRegisterDetails(FillingData.CashRegister);
		FillPropertyValues(Object, CashRegisterDetails);
		
		If Not ValueIsFilled(Object.FiscalDevice) Then
			
			Peripherals_ = RetailSales.CashRegisterCashRegisterFiscalDevice(FillingData.CashRegister);
			If ValueIsFilled(Peripherals_.FiscalDevice) Then
				Object.FiscalDevice = Peripherals_.FiscalDevice;
			EndIf;
			
		EndIf;
		
	EndIf;
EndProcedure

// The event handler is called on the server when the Cash shift list form is created on the server.
//
// Parameters:
//  Form - Form - the form to open.
//
Procedure ListFormOnCreateAtServer(Form) Export
	
EndProcedure

// The event handler is called on the server when the Cash shift document form is created on the server.
//
// Parameters:
//  Form - Form - the form to open.
//
Procedure DocumentFormWhenCreatedOnServer(Form) Export
	
EndProcedure

#EndRegion
