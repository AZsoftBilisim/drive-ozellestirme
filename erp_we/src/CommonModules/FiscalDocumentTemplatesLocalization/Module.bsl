#Region Public

// Generates a cash receipt template of operation based on receipt fiscalization data
// 
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   FiscalTransaction - Structure
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate
//
Procedure SalesSlipTemplate(Template, Data, FiscalTransaction, Parameters) Export
	
	
EndProcedure

// Generates a template for a shift opening report
// 
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate
//
Procedure TemplateReportOnOpeningShift(Template, Data, Parameters) Export
	
	
EndProcedure

// Generates a template for a report on closing a shift
// 
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate
//
Procedure TemplateReportOnClosingShift(Template, Data, Parameters) Export
	
	
EndProcedure

// Generates a Cur State report template
// 
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate
//   Data - See PeripheralsReceiptPrintersClientServer.OperationExecutionParameters
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate
//
Procedure TemplateReportOnCurrentState(Template, Data, Parameters) Export
	
	
EndProcedure

// Generates a template for a cash withdrawal report
// 
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate
//   Data - See PeripheralsReceiptPrintersClientServer.CollectionParameters
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate
//
Procedure CashWithdrawalTemplate(Template, Data, Parameters) Export
	
	
EndProcedure

// Generates a template for a cash deposit report
// 
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate
//   Data - See PeripheralsReceiptPrintersClientServer.CollectionParameters
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate
//
Procedure CashDepositTemplate(Template, Data, Parameters) Export
	
	
EndProcedure

// Generates a template for an info receipt report
// 
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate
//   Data - See PeripheralsReceiptPrintersClientServer.OperationExecutionParameters
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate
//
Procedure InfoReceiptTemplate(Template, Data, Parameters) Export
	
	
EndProcedure

#EndRegion
