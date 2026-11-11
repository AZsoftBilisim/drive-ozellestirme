
#Region Public

// Returns an object of an external report or treatment.
// Important:
//   the function option "use additional processing Reports"
//     must be Checked by the calling code.
//
//
// Parameters:
//   ExternalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors - plug-in report or processing.
//
// Returns: 
//   - ExternalDataProcessor - The object of connected processing.
//   - ExternalReport     - The object of the connected report.
//   - Undefined           - If an incorrect link is passed.
//
Function ExternalDataProcessorObject(ExternalDataProcessor) Export
	
	Return AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(ExternalDataProcessor);
	
EndFunction

// Enables external processing (report)
//   For more information, see additional processing Reports.Enable external processing().
//
// Parameters:
//   ExternalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors - plug-in report or processing.
//
// Returns:
//   - String       - The name of the connected report or processing.
//   - Undefined - If an incorrect link is passed.
//
Function AttachExternalDataProcessor(ExternalDataProcessor) Export
	
	Return AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(ExternalDataProcessor);
	
EndFunction

// It is determined by the use of a discount (margin) for the accrual of bonus points.
// 
// Parameters:
//  DiscountMarkup - CatalogRef.DiscountsMarkups - - discount (mark-up) for which verification is performed
// 
// Returns:
//  Boolean - True , used
Function ThisIsDiscountForBonusPoints(DiscountMarkup) Export
	
	Return DiscountsMarkupsServer.ThisIsDiscountForBonusPoints(DiscountMarkup);
	
EndFunction

#EndRegion