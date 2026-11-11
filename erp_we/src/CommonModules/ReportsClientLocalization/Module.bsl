
#Region Public

// Handler for double-clicking, pressing the Enter key, or hyperlinks in a table document of a report form.
//
//Parameters:
// See ReportsClientOverridable.SpreadsheetDocumentSelectionHandler
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
EndProcedure

// Handler for decoding a table document in a report form.
//
//Parameters:
// 	See ReportsClientOverridable.SpreadsheetDocumentSelectionHandler
//
Procedure DetailProcessing(ReportForm, Item, Details, StandardProcessing) Export
	
	
EndProcedure

// Handler for additional decryption (menu of the table document of the report form).
//  See ReportsClientOverridable.AdditionalDetailProcessing
//
Procedure AdditionalDetailProcessing(ThisForm, Item, Details, StandardProcessing) Export
	
EndProcedure

// The command handler is added dynamically and attached to the handler "Podklyucheniya".
// Example of adding a command See ReportsOverridable.OnCreateAtServer.
//
// Parameters:
//   ReportForm - ClientApplicationForm - report form.
//   Command     - FormCommand     - the command that was called.
//   Result   - Boolean           - True if the command call was processed.
//
Procedure HandlerCommands(ReportForm, Command, Result) Export
	
	
EndProcedure

#EndRegion