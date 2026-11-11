////////////////////////////////////////////////////////////////////////////////
// The module "Provision in documents (Server call)", contains procedures and functions
// that serve the operation of the mechanism for reserving and ensuring the needs for documents that call the server"
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Parameters:
//  Ref - AnyRef - a link to an order that has built-in commands for creating an assignment adjustment
//  AdditionalParameters - Structure - Structure with fields:
//  * IDInStorage - String - A unique identifier to put the goods of the document in the storage
//  * ThisIsWithdrawalOfReserve - Boolean - True if the data needs to be obtained for a reserve withdrawal operation, False if for a reservation operation
//  Returns:
//   Structure - Document data required to execute the assignment adjustment creation command
Function DocumentDataForCreatingDestinationAdjustment(Ref, AdditionalParameters) Export
	Return ProvisionInDocumentsServer.DocumentDataForCreatingDestinationAdjustment(Ref, AdditionalParameters);
EndFunction

// It is used to check the possibility of opening the processing of filling in the assignment correction.
// Parameters:
//  ThisIsReservation - Boolean - True if it is necessary to open processing for reservation, false if it is necessary to withdraw the reserve.
//  Ref - DefinedType.ExpectedShipment - a link to the order in which the commands for separate reserving and removing the reserve are embedded.
// Returns:
//  Structure - structure with fields:
//   * DocumentAssignment - CatalogRef.Assignments - the purpose of the order.
//   * ThereAreGoodsToSeparateProvision - Boolean - It is true if the order has goods for separate provision.
//   * ThereAreGoodsToThirdPartyStandAloneCollateral - Boolean - True if there are goods to a separate provision used by the order, but not related to the order.
//   * ThereAreGoodsToWithdrawReserve - Boolean - It is true if there are goods on order to remove the separation.
//   * HaveAccessToThirdPartyReserveWithdrawals - Boolean - True, if there are goods to be separated for the purpose used by the order, but not related to the order.
Function CheckingPossibilityOfOpeningFillingInAssignmentCorrection(ThisIsReservation, Ref) Export
	Return ProvisionInDocumentsServer.CheckingPossibilityOfOpeningFillingInAssignmentCorrection(ThisIsReservation, Ref);
EndFunction

// Properties for forming the security status label in the order form.
//
// Parameters:
//  Modified - Boolean - indicates that the order has been modified in the form.
//  Ref - AnyRef - Link to the order.
//  ReadyForSupply - Boolean - an Indication that the document Has The Proper Status to Be Considered secured.
//  ProblemWithStartingJob - Boolean - True if, as a result of queries, it is determined that there are problems with starting the distribution of spare parts.
//
// Returns:
//  Structure - structure with fields:
//   * Title - String - the text displayed in the header of the hyperlink.
//   * PageName - String - the name of the page of the order form where the desired hyperlink is located.
//   * HyperlinkName - String - name of the form element of the displayed hyperlink.
//
Function PropertiesOfSoftwareStateHyperlink(Modified, Ref, ReadyForSupply, ProblemWithStartingJob = False) Export
	
	Return ProvisionInDocumentsServer.PropertiesOfSoftwareStateHyperlink(
		Modified,
		Ref,
		ReadyForSupply,
		ProblemWithStartingJob);
	
EndFunction

// In the order form, checks that the document is completed.
//
// Parameters:
//  Ref - AnyRef - Link to the order.
//
// Returns:
//  Boolean - True if the document is held, False otherwise
//
Function HyperlinkStateOfProvisionClickDocumentCompleted(Ref) Export
	
	Return ProvisionInDocumentsServer.HyperlinkStateOfProvisionClickDocumentCompleted(Ref);
	
EndFunction

// Checks the availability of inventory allocation tasks for orders.
//
// Parameters:
//  Orders - Array of AnyRef - array of orders.
//
// Returns:
//  Boolean - True if there are tasks, False otherwise
//
Function ThereAreTasksForOrders(Orders) Export
	Return ProvisionInDocumentsServer.ThereAreTasksForOrders(Orders);
EndFunction

// If the background inventory allocation task is not running, then it starts it.
Procedure CheckToRunBackgroundInventoryAllocationJob() Export
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

// Checks whether there are inventory allocation tasks for at least one order of a specific document type.
//
// Parameters:
//  FullNamesOfDocuments - String - full names of documents displayed in a comma-separated list.
//
// Returns:
//  Array of AnyRef - orders of tasks from the inventory distribution task register
//
Function TasksForOrdersByType(FullNamesOfDocuments) Export
	Return ProvisionInDocumentsServer.TasksForOrdersByType(FullNamesOfDocuments);
EndFunction

// Performs the action of filling in the security in the order from the list of orders.
//
// Parameters:
//  CommandParameter - Array of AnyRef - orders highlighted in the list for performing provisioning actions.
//  CommandName - String - the symbol of the command "ACTION_TO SUPPORT" or "ACTION_TO LOAD"
//                        or "ACTION_TO RESERVE" or "ACTION_TO PROVIDE" or "ROLLBACK ACTION_TO LOAD".
//  UUID - UUID - the unique ID of the form that will
//                                                       store the result of the execution in the background.
//  EmbeddingParameters - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
// Returns:
//  Structure - the result of performing actions on orders.
//
Function PerformActionInOrderList(CommandParameter, CommandName, UUID, EmbeddingParameters = Undefined) Export
	
	Result = ProvisionInDocumentsServer.PerformActionForOrders(
		CommandParameter,
		CommandName,
		UUID,
		EmbeddingParameters);
		
	Return Result;
	
EndFunction

// Performs the action of filling in the security in the order from the list of orders after setting the question about the shipment by a single date.
//
// Parameters:
//  Parameters - Structure - parameter structure:
//   * ActionCode - String - the symbol of the command "ACTION_SUPPLY" or "ACTION_LOAD"
//                   or "ACTION_RESERVE" or " ACTION_SUPPLY"
//   * FillParameters - Structure - parameter structure:
//     ** UncheckShipByOneDateFlag - Boolean - the result of answering a question about a single-date shipment.
//     ** FillShippingDateWithSingleDate - Boolean - the result of answering a question about a single-date shipment.
//   * Orders - Array of AnyRef - orders to set the action.
//   * EmbeddingParameters - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//  UUID - UUID - the unique ID of the form that will
//                                                       store the result of the execution in the background.
//
// Returns:
//  Structure - structure with fields:
//   * ErrorList - Array - an array containing the texts of document processing errors.
//   * QuantityProcessed - Number - the number of documents processed.
//
Function PerformActionForOrdersAfterQuestionByBackgroundTask(Parameters, UUID) Export
	
	Result = ProvisionInDocumentsServer.PerformActionForOrdersAfterQuestionByBackgroundTask(
		Parameters, UUID);
	Return Result;
	
EndFunction

// Called from the handler for getting the data for selecting the "Security Options"enumeration.
// It is intended for getting the necessary data on the server.
// Parameters:
//  Parameters - Structure - the structure of parameters for getting server data.
//
// Returns:
//  Structure - structure with fields:
//   * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - the unit of measurement of the item in the line.
//   * YouNeedToSpecifySeriesInLine - Boolean - the need to specify the series for the order item and warehouse.
//   * AllowableVariance - Number - the permissible deviation of the measured units of measurement, if the item is measured.
//   * PackagingFactor - Number - the packing factor specified in the line.
//
Function ProcessingOfDataAcquisitionOfSoftwareOptionSelection(Parameters) Export
	
	Return ProvisionInDocumentsServer.ProcessingOfDataAcquisitionOfSoftwareOptionSelection(Parameters);
	
EndFunction

// Returns the shipping date set in the document header, if there is one in the document.
//
// Parameters:
//   AvailableRemainingDocumentParameters - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
// Returns:
//  Date, Undefined - the date of shipment from the document header.
//
Function TheShipmentDateOfAllLinesIsASingleDate(AvailableRemainingDocumentParameters) Export
	
	Return ProvisionInDocumentsServer.TheShipmentDateOfAllLinesIsASingleDate(AvailableRemainingDocumentParameters);
	
EndFunction

// Checks whether there are tasks for orders to distribute inventory.
//
// Parameters:
//   Orders - Array of AnyRef - orders to check.
//
// Returns:
//  Boolean - True if you need to update, otherwise False.
//
Function NeedToUpdateAvailabilityAfterRecording(Orders) Export
	
	Return Not ProvisionInDocumentsServer.ThereAreTasksForOrders(Orders);
	
EndFunction

// Performs provisioning actions in order lists, where documents with different provisioning embedding parameters are displayed.
// Parameters:
//  ActionCode - String - "ACTION_LOAD", "ACTION_RESERVE", "ACTION_SUPPLY", "ACTION_SUPPLY".
//  AllOrders - Array - links selected in the list of documents.
//  Ref - DocumentRef - a link to get the object manager module where the parameters function is located.
//  UUID - UUID - id of the document list form.
// Returns:
//  Structure - a lengthy operation or a structure for asking a question.
Function PerformActionInListOfOrdersOfDifferentTypes(ActionCode, AllOrders, Ref, UUID) Export
	
	Return ProvisionInDocumentsServer.PerformActionInListOfOrdersOfDifferentTypes(
		ActionCode,
		AllOrders,
		Ref,
		UUID);
	
EndFunction

// Performs collateral actions in order lists,
//  where documents are displayed that have different collateral embedding parameters after a question about a single-date shipment.
// Parameters:
//  ResultOfActions - Structure - structure of parameters for performing actions.
//  UUID - UUID - id of the document list form.
// Returns:
//  Structure - a lengthy operation or a structure for asking a question.
Function PerformActionInListOfOrdersOfDifferentTypesAfterQuestion(ResultOfActions, UUID) Export
	
	Return ProvisionInDocumentsServer.PerformActionInListOfOrdersOfDifferentTypesAfterQuestion(
		ResultOfActions,
		UUID);
	
EndFunction

#EndRegion

#Region Internal

#EndRegion
