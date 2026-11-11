
#Region Public

// Checking the correctness of the Bank account
//
// Parameters:
//  Number        - String - Bank account number.
//  CurrencyAccount - Boolean - Indicates whether the account is a currency account.
//  ErrorText  - String - text of the error message.
//
// Returns:
//  Boolean - True - the control key is correct, False - the control key is not correct.
//
Function CheckIfAccountNumberIsCorrect(Val Number, CurrencyAccount = False, ErrorText = "") Export
	
	Result = True;
	
	
	Return Result;
	
EndFunction

// Verifies that the transferred account number is Treasury.
//
// Parameters:
//  AccountNumber - String
//  
// Returns:
//  Boolean
//
Function ThisIsTreasuryAccount(AccountNumber) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

// Checks that the transferred BIC is the code of the Territorial Body of the Federal Treasury.
//
// Parameters:
//  CodeOfBank - String
//  
// Returns:
//  Boolean
//
Function ThisIsBICTOFC(CodeOfBank) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

// Verifies that the transferred account number is a single treasury account.
//
// Parameters:
//  AccountNumber - String
//  
// Returns:
//  Boolean
///
Function ThisIsSingleTreasuryAccount(AccountNumber) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction


#EndRegion

#Region Internal


// Forms of payment for applications for non-cash payment.
// 
// Returns:
//  Array of EnumRef.PaymentForms - Forms Of Payment For Applications For Non-Cash Payment
Function FormsOfPaymentForApplicationsForNonCashPayment() Export

	PaymentForms = New Array;
	
	
	Return PaymentForms;

EndFunction

#EndRegion

#Region Private


#EndRegion
