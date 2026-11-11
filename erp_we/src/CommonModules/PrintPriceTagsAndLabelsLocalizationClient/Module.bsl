////////////////////////////////////////////////////////////////////////////////
// Procedures and functions used in the processing of purchase log documents
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Prints a sample of localized labels
// 
// Parameters:
// 	ParametersForSamplePrinting - Structure - Print options
// 	CommandParameter - Structure - Command parameter
// 	Context - ClientApplicationForm - The context to retrieve data
Procedure PrintSample(ParametersForSamplePrinting, CommandParameter, Context) Export
EndProcedure

// Prints excise stamp labels
// 
// Parameters:
// 	ParametersForPrintingExciseStamps - Structure - Print options
// 	Context - ClientApplicationForm - The context to retrieve data
Procedure PrintingLabelExciseStamps(ParametersForPrintingExciseStamps, Context) Export
EndProcedure

#EndRegion

