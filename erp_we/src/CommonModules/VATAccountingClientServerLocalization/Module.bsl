
#Region Public

#Region ProceduresForCheckingCorrectnessOfCustomsDeclarationNumber

// Returns the structure of the registration number of the customs declaration according to the transmitted full number of the goods declaration,
// and also checks the correctness of entering the number of the customs declaration.
//
// Parameters:
//	CustomsDeclarationNumber - String - customs Declaration number or registration number of the customs Declaration.
//	BeginningOfCorrectPeriod - Date - start date of the verification period.
//	EndOfCorrectPeriod - Date - the end date of the verification period.
//
// Returns:
//	Structure:
//		* RegistrationNumber - String - the registration number of the customs declaration or an empty line if it
//											could not be determined.
//		* GoodsSequenceNumber - String - serial number of the product.
//		* ErrorCode - Number - error code.
//
Function CheckCorrectnessOfCustomsDeclarationNumber(CustomsDeclarationNumber,
														BeginningOfCorrectPeriod = Undefined,
														EndOfCorrectPeriod = Undefined) Export
	
	NumberStructure = New Structure("RegistrationNumber, GoodsSequenceNumber, ErrorCode", "", "", 0);
	
	
	Return NumberStructure;
	
EndFunction

// Returns a text description of the error when entering the customs declaration number.
//
// Parameters:
//	ErrorCode - Number - error code
//
// Returns:
//	String - text description of the error in the number of the customs declaration.
//
Function TextOfErrorInCustomsDeclarationNumber(ErrorCode) Export
	
	ErrorText = "";
	
	
	Return ErrorText;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// supplements the list of VAT taxation types for which the Attributes of the rate and the amount of VAT are hidden in the documents.
//
// Parameters:
//  Array - See VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails
//
Procedure AddTaxTypesThatHideVATDetails(Array, NameOfVATRateField = "") Export
	
	
EndProcedure

// Calculates the VAT amount based on the amount and tax flags.
//
// Parameters:
//  Sum            - Number - the amount from which taxes should be calculated;
//  VATRate        - Number, CatalogRef.VATRates - Value or reference to the VAT rate.
//  AmountIncludesVAT - Boolean - whether VAT is included in the amount ("inside" or " above");
//  VATTaxation - EnumRef.VATTaxationTypes - document taxation
//
// Returns:
//  Number - the amount of VAT received.
//
Function CalculateVATAmount(Sum, VATRate, AmountIncludesVAT = True, VATTaxation = Undefined) Export

	VATAmount = Undefined;
	
	
	Return VATAmount;
	
EndFunction

#EndRegion
