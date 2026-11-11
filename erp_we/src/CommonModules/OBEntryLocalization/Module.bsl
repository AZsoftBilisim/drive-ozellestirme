#Region Public

#Region Initialize

// Fills in the correspondence table of the document tree section
// entering balances and business operations.
//
// Parameters:
//  DescriptionOfBalanceEntrySections - Structure - Structure initialized by the procedure
//                                  Initialize the account description() with the values filled in.
// 	ConsiderFOS - Boolean - Accounting for functional options when building a table.
//
Procedure FillInComplianceTableForBusinessOperationsSection(DescriptionOfBalanceEntrySections, ConsiderFOS) Export
EndProcedure

#EndRegion

#Region EventHandlers

#Region EventHandlersEnteringCashBalances

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringCashBalancesProcessingOfTransactions(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringCashBalancesProcessingFillChecks(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringCashBalancesProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringCashBalancesProcessingDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryCashBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringCashBalancesWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringCashBalancesWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringCashBalancesBeforeDeleting(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringBalances

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringBalancesProcessingOperations(Object, Cancel, PostingMode) Export
	
	
	Return;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringBalancesProcessingFillChecks(Object, Cancel, CheckedAttributes, NotCheckedAttributes) Export
	EnteringExpenseBalancesForUSNProcessingFillInChecks(Object, Cancel, CheckedAttributes, NotCheckedAttributes);
	Return;
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringBalancesProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringResiduesProcessingDeletions(Object, Cancel) Export
	
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	

	Return;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringWriteBalances(Object, Cancel) Export
	Return;
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringResiduesWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringSettlementBalances

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringBalancesOfSettlementsProcessingOfTransactions(Object, Cancel, PostingMode) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringSettlementBalancesProcessingFillChecks(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringBalancesOfSettlementsProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringSettlementBalancesProcessingDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryARAPBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;

EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringAccountBalancesWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - The object being processed.
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringAccountBalancesWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringSettlementBalancesBeforeDeletion(Object, Cancel) Export
	Return;	
EndProcedure


#EndRegion

#Region EventHandlersEnteringVATBalancesSubmitted

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringVATBalancesSubmittedProcessing(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringVATBalancesSubmittedProcessingFillVerification(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringVATBalancesSubmittedProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOfVATSubmittedProcessingDeletionOfTransaction(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringVATBalancesPresentedBeforeRecording(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringRemainingVATPresentedAtTimeOfRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringVATBalancesPresentedDuringCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringVATBalancesSubmittedBeforeDeletion(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringBalancesAboutSalesForPastPeriods

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringBalancesOfSalesForPastPeriodsProcessingOfTransactions(Object, Cancel, PostingMode) Export
	Return;
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringSalesBalancesForPastPeriodsProcessingFillInChecks(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringBalancesOfSalesForPastPeriodsProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOnSalesForPastPeriodsProcessingDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntrySalesForPastPeriodsBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOfSalesForPastPeriodsWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringBalancesOfSalesForPastPeriodsWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringBalancesAboutPastSalesBeforeDeleting(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringBalancesOnFinancialInstruments

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringBalancesOnFinancialInstrumentsProcessing(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringBalancesOnFinancialInstrumentsProcessingFillChecks(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringBalancesOnFinancialInstrumentsProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOnFinancialInstrumentsProcessingDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryFinancialInstrumentsBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOnFinancialInstrumentsWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringBalancesOnFinancialInstrumentsWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringBalancesOnFinancialInstrumentsBeforeDeletion(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringBalancesOtherExpenses

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringBalancesOtherExpensesProcessing(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringBalancesOtherExpensesProcessingFillChecks(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringBalancesOtherExpensesProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOtherExpensesProcessingDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryOtherExpensesBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOtherRecordingCosts(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringBalancesOtherCopyingCosts(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringBalancesOtherExpensesBeforeDeletion(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringBalancesOfOtherAssetsLiabilities

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesProcessing(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesProcessingFillChecks(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure InputOfBalancesOfOtherAssetsLiabilitiesProcessingOfFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesProcessingOfDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryOtherAssetsAndLiabilitiesBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesBeforeDisposal(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringExpenseBalancesForUSN

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringExpenseBalancesAtUSNProcessing(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringExpenseBalancesForUSNProcessingFillInChecks(Object, Cancel, CheckedAttributes, NotCheckedAttributes) Export
	
	
	Return;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringExpenseBalancesForUSNProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringExpenseBalancesForUSNProcessingDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringExpenseBalancesForUSNBeforeRecording(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringExpenseBalancesForUSNWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringBalanceOfExpensesForUSNWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringExpenseBalancesForUSNBeforeDeleting(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringAccountBalancesForAcquiring

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringBalancesOfSettlementsOnAcquiringProcessingOfTransactions(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringBalancesOfAcquiringCalculationsProcessingFillCheck(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringBalancesOfSettlementsOnAcquiringProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOfSettlementsOnAcquiringProcessingOfDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryAcquiringContractARAPBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesOfAcquiringCalculationsWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringBalancesOfAcquiringCalculationsWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringBalancesOfAcquiringCalculationsBeforeDeleting(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringBalancesWithAccountability

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure EnteringBalancesWithAccountablePersonsProcessingResults(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringBalancesWithAccountablePersonsProcessingFillChecks(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringBalancesWithAccountablePersonsProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesWithAccountablePersonsHandlingDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryARAPAdvanceHoldersBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringBalancesWithAccountHoldersWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringBalancesWithAccountsWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringBalancesWithAccountsBeforeDeleting(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringInventoryBalances

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure InputOfResiduesOfTMTSVOperationProcessing(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringResiduesOfTMTSVOperationProcessingFillingChecks(Object, Cancel, CheckedAttributes) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure InputOfResiduesTMTSVOperationProcessingOfFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure InputOfResiduesTMTSVOperationProcessingOfRemovalOfWaste(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryInventoryInOperationBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringRemnantsOfTMTSVOperationDuringRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringRemnantsOfTMTSVOperationWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringResiduesOfTMTSVOperationBeforeDisposal(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#Region EventHandlersEnteringProductBalances

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure InputOfGoodsBalancesProcessingOfGoods(Object, Cancel, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure EnteringProductBalancesProcessingFillChecks(Object, Cancel, CheckedAttributes) Export
	Return;
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure EnteringProductBalancesProcessingFilling(Object, FillingData, StandardProcessing) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure EnteringProductBalancesProcessingDeletions(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure OBEntryGoodsBeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure EnteringProductBalancesWhenRecording(Object, Cancel) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object            - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure EnteringProductBalancesWhenCopying(Object, CopiedObject) Export
	Return;	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel  - Boolean - Flag for refusing to delete.
//
Procedure EnteringProductBalancesBeforeDeleting(Object, Cancel) Export
	Return;	
EndProcedure

#EndRegion

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	Return;	
EndProcedure

// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export
	Return;
EndProcedure

#Region PlugInReportCommands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringBalancesAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringSettlementBalancesAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringCashBalancesAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringVATBalancesSubmittedAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnterBalancesOnSalesForPastPeriodsAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringFinancialInstrumentBalancesAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringBalancesOtherExpensesAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringExpenseBalancesForUSNAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringAccountBalancesForAcquiringAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringBalancesWithAccountabilityAddReportingCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringInventoryBalancesInOperationAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure EnteringProductBalancesAddReportCommands(ReportsCommands, Parameters) Export
	Return;	
EndProcedure

#EndRegion

#Region PluggablePrintCommands

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringSettlementBalancesAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringCashBalancesAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringVATBalancesPresentedAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnterBalancesAboutPastSalesAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringFinancialInstrumentBalancesAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringBalancesOtherExpensesAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringExpenseBalancesAtUSNAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringBalancesOfAcquiringCalculationsAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringBalancesWithAccountsAddPrintCommands(PrintCommands) Export
	Return;	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringLeftoversAddPrintCommands(PrintCommands) Export
	Return;
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure EnteringProductBalancesAddPrintCommands(PrintCommands) Export
	Return;
	
EndProcedure

#EndRegion

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	Return;	
EndProcedure


#EndRegion
#Region RegAccountingTransactions

#Region TransactionsRegAccountingEnteringBalances

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringBalancesForReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringBalancesRequestTextTTReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region TransactionsRegAccountingEnteringCashBalances

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringCashBalancesForReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function CashRequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region TransactionsRegAccountingEnteringBalancesOfSettlements

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringBalancesOfSettlementsForReflectionInLocalAccounting() Export
	
	ReflectionTexts = New Array; 
	
	
	Return StrConcat(ReflectionTexts, TMCommonUse.QuerySeparatorInJoin());
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringSettlementBalancesRequestTextTTReflectedInLocalAccounting() Export
	
	Return "";

EndFunction

#EndRegion

#Region PostingRegAccountingEnteringVATBalancesPresented

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringVATBalancesPresentedForReflectionInLocalAccounting() Export

	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringVATBalancesOfSubmittedTextOfRequestTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region PostingRegAccountingEnteringBalancesOnSalesForPastPeriods

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringSalesBalancesForPastPeriodsToBeReflectedInLocalAccounting() Export
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringBalancesOnSalesForPastPeriodsQueryTextTTReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region TransactionsRegAccountingEnteringBalancesOnFinancialInstruments

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringBalancesOnFinancialInstrumentsForReflectionInLocalAccounting() Export
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringBalancesOnFinancialInstrumentsRequestTextTTReflectionInLocalAccounting() Export


	Return "";
	
EndFunction

#EndRegion

#Region PostingRegAccountingEnteringBalancesOtherExpenses

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringBalancesOtherExpensesForReflectionInLocalAccounting() Export
	Return "";
	
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringBalancesOtherExpensesRequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region TransactionsRegAccountingEntryOfBalancesOfOtherAssetsLiabilities

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringBalancesOfOtherAssetsLiabilitiesForReflectionInLocalAccounting() Export
	Return "";	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringBalancesOfOtherAssetsLiabilitiesRequestTextTTReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region TransactionsRegAccountingInputOfBalancesOfExpensesAtUSN

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringExpenseBalancesAtUSNForReflectionInLocalAccounting() Export
	Return "";	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringExpenseBalancesForUSNRequestTextTTReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region TransactionsRegAccountingEnteringBalancesOfSettlementsOnAcquiring

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringBalancesOfAcquiringCalculationsForReflectionInLocalAccounting() Export
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringBalancesOfAcquiringSettlementsRequestTextTTReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region TransactionsRegAccountingEnteringBalancesWithAccountablePersons

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringBalancesWithAccountablePersonsForReflectionInLocalAccounting() Export
	Return "";
	
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringBalancesWithAccountablePersonsRequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region PostingRegAccountingEnteringProductBalances

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringProductBalancesToBeReflectedInLocalAccounting() Export
	
	ReflectionTexts = New Array;
	
	
	Return StrConcat(ReflectionTexts, TMCommonUse.QuerySeparatorInJoin());
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringProductBalancesRequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region TransactionsRegAccountingDataEntryOnIncomeTax

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function EnteringIncomeTaxDataTextOfReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function EnteringDataOnIncomeTaxTextOfRequestTTReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#EndRegion
#Region Posting

#Region HandlersOfCarryingOutEntryOfCashBalances

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringCashBalancesAddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringCashBalancesAndAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region HandlersForEnteringBalances

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesAddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure


// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringBalancesRegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region HandlersForEnteringSettlementBalances

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringAccountBalancesAddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringSettlementBalancesAndAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region HandlersConductingInputOfVATBalancesSubmitted

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesOfVATSubmittedToSupplementTextsOfRequests(Query, QueryTexts, Registers) Export
	
	
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringVATBalancesSubmittedToRegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region HandlersConductingBalanceEntryIAInternationalAccounting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesOfIaInternationalAccountingSupplementTextsOfRequests(Query, QueryTexts, Registers) Export
	Return;	
EndProcedure

#EndRegion

#Region HandlersEnterBalancesOfSalesForPastPeriods

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesOnSalesForPastPeriodsSupplementTextsOfRequests(Query, QueryTexts, Registers) Export
	Return;
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringBalancesOfSalesForPastPeriodsRegisterAccountingMechanisms(DocumentMechanisms) Export
	Return;	
EndProcedure

#EndRegion

#Region HandlersOfCarryingOutEntryOfOSBalancesInternationalAccounting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringFABalancesInternationalAccountingSupplementTextsOfRequests(Query, QueryTexts, Registers) Export
	Return;	
EndProcedure

#EndRegion

#Region HandlersEnterBalancesOnFinancialInstruments

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesOnFinancialInstrumentsToSupplementTextsOfRequests(Query, QueryTexts, Registers) Export
	Return;
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringBalancesOnFinancialInstrumentsAndAccountingMechanisms(DocumentMechanisms) Export
	Return;
EndProcedure

#EndRegion

#Region TransactionHandlersEnteringBalancesOtherExpenses

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesOtherExpensesSupplementTextsOfRequestsForHolding(Query, QueryTexts, Registers) Export
	Return;	
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringBalancesOtherExpensesRegisterAccountingMechanisms(DocumentMechanisms) Export
	Return;	
EndProcedure

#EndRegion

#Region HandlersEnterBalancesOfOtherAssetsLiabilities

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure InputOfBalancesOfOtherAssetsLiabilitiesSupplementTextsOfRequestsForConducting(Query, QueryTexts, Registers) Export
	Return;
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringBalancesOfOtherAssetsLiabilitiesAndAccountingMechanisms(DocumentMechanisms) Export
	Return;	
EndProcedure

#EndRegion

#Region HandlersForEnteringExpenseBalancesAtUSN

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesOfExpensesForUSNSupplementTextsOfRequestsForConducting(Query, QueryTexts, Registers) Export


	Return;
	
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringExpenseBalancesAtUSNRegisterAccountingMechanisms(DocumentMechanisms) Export
	

	Return;
	
EndProcedure

#EndRegion

#Region HandlersEnteringBalancesOfSettlementsOnAcquiring

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesOfSettlementsOnAcquiringSupplementTextsOfRequestsForConducting(Query, QueryTexts, Registers) Export
	Return;
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringBalancesOfSettlementsOnAcquiringAndAccountingMechanisms(DocumentMechanisms) Export
	Return;	
EndProcedure

#EndRegion

#Region HandlersOfCarryingOutEntryOfBalancesWithAccountablePersons

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringBalancesWithAccountablePersonsAddRequestTexts(Query, QueryTexts, Registers) Export
	Return;
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringBalancesWithAccountabilityRegisterAccountingMechanisms(DocumentMechanisms) Export
	Return;
EndProcedure

#EndRegion

#Region HandlersOfCarryingOutInputOfRemainingGoods

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure EnteringProductBalancesAddRequestTexts(Query, QueryTexts, Registers) Export
	Return;
EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure EnteringProductBalancesAndAccountingMechanisms(DocumentMechanisms) Export
	Return;
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

// To complete the description of the business operations of entering the Balance of the BHA.
// 
// Parameters:
//  DescriptionOfBusinessOperationsForEnteringBalances - See OBEntryServer.InitializeDescriptionOfBusinessTransactionForEnteringBalances
// 	ConsiderFOS - Boolean - Accounting for functional options when building a table.
// 	OrderInTree - Number -
// 
Procedure ToCompleteDescriptionOfBusinessOperationsOfEnteringBalanceOfBHA(DescriptionOfBusinessOperationsForEnteringBalances, ConsiderFOS, OrderInTree) Export

	
EndProcedure


#EndRegion
