
#Region Internal

#Region FormEvents

#Region PrintingDetailsOfSales

// A procedure called from the form event handler of the same name.
//
// Parameters:
//  Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel					- Boolean - indicates that the form was not created.
//  StandardProcessing	- Boolean - indicates whether standard (system) event processing is performed
//
Procedure WhenCreatingAtServerAttributesOfPrintingImplementation(Form, Cancel, StandardProcessing) Export
	
	
	Return;
	
EndProcedure

#EndRegion

#EndRegion

#Region MarkedProducts

// Returns:
// See WarehousesLocalization.MarkedProductsAreUsed
Function MarkedProductsAreUsed() Export

	Return WarehousesLocalization.MarkedProductsAreUsed();

EndFunction

// Parameters:
// PackageSize - Number - Number of requests in the returned packet (return value)
// Returns:
// String - the text of the batch request, the fragment to add
Function TextOfMarkingRequest(PackageSize = 0) Export
	
	QueryText = "";
	
	
	Return QueryText;
	
EndFunction

Procedure TransferBarcodesOfPackages(Form, PackageBarcodes, TSName = "PackageBarcodes") Export


EndProcedure

#EndRegion

#Region CheckingCorrectnessOfFillingOutSalesDocument

// Complements the array of checks on the correctness of filling out the sales document.
//
// Parameters:
//  ChecksArray - Array of String
//  ParametersForCheckingCorrectnessOfFilling - See SalesServer.ParametersForCheckingCorrectnessOfFillingOutSalesDocument
//
Procedure CompleteArrayOfChecksOnCorrectnessOfFillingOutSalesDocument(ChecksArray, ParametersForCheckingCorrectnessOfFilling) Export

	
EndProcedure


// Supplements requests for verification of the correctness of filling out the sales document.
//
// Parameters:
//  CheckItems - String
//  QueryText - String
//  QueryOptions - Structure of KeyAndValue
//  ParametersForCheckingCorrectnessOfFilling - See SalesServer.ParametersForCheckingCorrectnessOfFillingOutSalesDocument
//
Procedure CompleteRequestsForVerificationOfCorrectnessOfFillingOutSalesDocument(CheckItems, QueryText, QueryOptions, ParametersForCheckingCorrectnessOfFilling) Export


EndProcedure

// Displays an error message when checking the correctness of the sales document.
//
// Parameters:
//  CheckItems - String
//  Selection - QueryResultSelection
//  ParametersForCheckingCorrectnessOfFilling - See SalesServer.ParametersForCheckingCorrectnessOfFillingOutSalesDocument
//  Cancel - Boolean
//
Procedure ReportErrorsInCheckingCorrectnessOfSalesDocument(CheckItems, Selection, ParametersForCheckingCorrectnessOfFilling, Cancel) Export


EndProcedure


#EndRegion

#EndRegion

#Region Private


#EndRegion
