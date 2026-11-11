
////////////////////////////////////////////////////////////////////////////////
// The module "Invoice Server calls", contains procedures and functions for
// processing invoices.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// For the passed grouping, returns parameters for opening the invoice form for orders.
// See InvoicesClient.OpenFormForCreatedDocuments.
//
// Parameters:
//  GroupingOrders				 - Array - contains arrays of groups of orders to create a document for
//  															See InvoicesClient.DataForPlacingOrders.
//  FormParametersForCreatedDocuments	 - Structure - parameters for the General Form.Forms of created documents.
//  ErrorList						 - Structure - error list.
//  ErrorField							 - String - the value that is set in the field property of the message object to the User.
//
// Returns:
//  Structure - Structure with fields:
//  		Formname	 - String
//  		Parameters	 - Structure.
//
Function IssueInvoicesForOrders(GroupingOrders, FormParametersForCreatedDocuments, ErrorList, ErrorField) Export
	
	Result = InvoicesServer.IssueInvoicesForOrders(
		GroupingOrders,
		FormParametersForCreatedDocuments,
		ErrorField);
	
	ErrorList = Result.ErrorList;
	Return Result.ParametersOfCreatedDocuments;
	
EndFunction

// For the passed grouping, returns parameters for opening the invoice form to be reissued for orders.
// See InvoicesClient.OpenFormForCreatedDocuments.
//
// Parameters:
//  GroupingOrders				 - Array - contains arrays of groups of orders to create a document for
//  															See InvoicesClient.DataForProcessingOrders.
//  FormParametersForCreatedDocuments	 - Structure - parameters for the General Form.Forms of created documents.
//  ErrorList						 - Structure - error list.
//  ErrorField							 - String - the value that is set in the field property of the message object to the User.
//
// Returns:
//  Structure - Structure with fields:
//  		Formname	 - String
//  		Parameters	 - Structure.
//
Function IssueInvoicesForOrders_(GroupingOrders, FormParametersForCreatedDocuments, ErrorList, ErrorField) Export
	
	Result = InvoicesServer.IssueInvoicesForOrders_(
		GroupingOrders,
		FormParametersForCreatedDocuments,
		ErrorField);
	
	ErrorList = Result.ErrorList;
	Return Result.ParametersOfCreatedDocuments;
	
EndFunction

#EndRegion