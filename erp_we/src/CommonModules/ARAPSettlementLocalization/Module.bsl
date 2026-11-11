
#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export	

EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export

	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export

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
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export


EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.ARAPSettlement) Then

		// The act of offsetting (Microsoft Word)
		TemplateName = "PF_DOC_OffsettingAct" + "_" + Common.DefaultLanguageCode();
		If Metadata.Documents.ARAPSettlement.Templates.Find(TemplateName) <> Undefined Then
			
			SettlementOfARAP = New Array;
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.PaymentByGiftCard);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.Barter);
			SettlementOfARAP.Add(Enums.KindsOfARAPSettlements.Arbitrary);
			
			PrintCommand = PrintCommands.Add();
			PrintCommand.Id = "MicrosoftWordOffsetAct";
			PrintCommand.Presentation = NStr("vi = 'Biên bản đối trừ công nợ (Microsoft Word)';
											|ru = 'Акт взаимозачета (Microsoft Word)';
											|en = 'Netting agreement (Microsoft Word)'; fa = 'Netting agreement (Microsoft Word)';
											|it = 'Atto di compensazione (Microsoft Word)';
											|pl = 'Akt wzajemnych rozliczeń (Mikrosoft Word)';
											|tr = 'Mahsuplaşma anlaşması (Microsoft Word)'");
			PrintCommand.CheckPostingBeforePrint = True;
			AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
																"OperationKind",
																SettlementOfARAP,
																DataCompositionComparisonType.InList);
		EndIf;
		
		Assignment = New Array;
		Assignment.Add(Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties);
		Assignment.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties);
		Assignment.Add(Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties);
		Assignment.Add(Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties);
		Assignment.Add(Enums.KindsOfARAPSettlements.Arbitrary);
		Assignment.Add(Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent);
		Assignment.Add(Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent);
		
		TypeCounterparty = New Array;
		TypeCounterparty.Add(Enums.ARAPSettlemenParticipantTypes.Client);
		TypeCounterparty.Add(Enums.ARAPSettlemenParticipantTypes.Vendor);
	
		// The act of assignment of debt (Microsoft Word)
		TemplateName = "PF_DOC_DebtAssignmentAct" + "_" + Common.DefaultLanguageCode();
		If Metadata.Documents.ARAPSettlement.Templates.Find(TemplateName) <> Undefined Then
			PrintCommand = PrintCommands.Add();
			PrintCommand.Id = "MicrosoftWordDebtAssignmentAct";
			PrintCommand.Presentation = NStr("vi = 'Biên bản chuyển nợ (Microsoft Word)';
											|ru = 'Акт переуступки долга (Microsoft Word)';
											|en = 'Debt assignment protocol (Microsoft Word)'; fa = 'Debt assignment protocol (Microsoft Word)';
											|it = 'Atto di cessione del debito (Microsoft Word)';
											|pl = 'Akt przeniesienia długu  (Microsoft Word)';
											|tr = 'Borç devir tutanağı (Microsoft Word)'");
			PrintCommand.CheckPostingBeforePrint = True;
			AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
																"OperationKind",
																Assignment,
																DataCompositionComparisonType.InList);
			AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
																"CounterpartyDebtorType",
																TypeCounterparty,
																DataCompositionComparisonType.InList);
			AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
																"CounterpartyCreditorType",
																TypeCounterparty,
																DataCompositionComparisonType.InList);
		EndIf;
		
		AssignmentBetweenOrganizations = New Array;
		AssignmentBetweenOrganizations.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany);
		AssignmentBetweenOrganizations.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany);
		AssignmentBetweenOrganizations.Add(Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany);
		AssignmentBetweenOrganizations.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany);
		AssignmentBetweenOrganizations.Add(Enums.KindsOfARAPSettlements.Arbitrary);
	
		// The act of assignment of debt between organizations (Microsoft Word)
		TemplateName = "PF_DOC_ActOfAssignmentOfDebtBetweenOrganizations" + "_" + Common.DefaultLanguageCode();
		If Metadata.Documents.ARAPSettlement.Templates.Find(TemplateName) <> Undefined Then
			PrintCommand = PrintCommands.Add();
			PrintCommand.Id = "ActOfAssignmentOfDebtBetweenMicrosoftWordOrganizations";
			PrintCommand.Presentation = NStr("vi = 'Biên bản chuyển nợ giữa các doanh nghiệp (Microsoft Word)';
											|ru = 'Акт переуступки долга между организациями (Microsoft Word)';
											|en = 'Debt assignment protocol intercompany (Microsoft Word)'; fa = 'Debt assignment protocol intercompany (Microsoft Word)';
											|it = 'Atto di cessione del debito tra le società (Microsoft Word)';
											|pl = 'Akt przeniesienia zobowiązania między firmami (Microsoft Word)';
											|tr = 'İş yerleri arasında borç devir tutanağı (Microsoft Word)'");
			PrintCommand.CheckPostingBeforePrint = True;
			PrintCommand.FunctionalOptions = "UseMultipleCompanies";
			AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
																"OperationKind",
																AssignmentBetweenOrganizations,
																DataCompositionComparisonType.InList);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter).
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "MicrosoftWordOffsetAct") Then 
		PrintParameters = New Structure;
		PrintParameters.Insert("TemplateName", "PF_DOC_OffsettingAct_ru");
        PrintParameters.Insert("TemplateSynonym",NStr("ru = 'Акт взаимозачета задолженности';
														|vi = 'AR/AP offset certificate';
														|en = 'AR/AP offset certificate'; fa = 'AR/AP offset certificate';
														|it = 'AR/AP offset certificate';
														|pl = 'AR/AP offset certificate';
														|tr = 'Takas sözleşmesi'"));
		PrintParameters.Insert("Id","MicrosoftWordOffsetAct");
		PrintParameters.Insert("DocumentNameTemplate", 
					NStr("ru = '[Organization]-[CounterpartyDebtor]-[Creditor] Акт взаимозачета задолженности №[Number] от [Date]';
						|vi = '[Organization]-[CounterpartyDebtor]-[Creditor] AR/AP offset certificate No.[Number] dated [Date]';
						|en = '[Organization]-[CounterpartyDebtor]-[Creditor] AR/AP offset certificate No.[Number] dated [Date]'; fa = '[Organization]-[CounterpartyDebtor]-[Creditor] AR/AP offset certificate No.[Number] dated [Date]';
						|it = '[Organization]-[CounterpartyDebtor]-[Creditor] AR/AP offset certificate No.[Number] dated [Date]';
						|pl = '[Organization]-[CounterpartyDebtor]-[Creditor] AR/AP offset certificate No.[Number] dated [Date]';
						|tr = '[Organization]-[CounterpartyDebtor]-[Creditor] [Date] Tarihli [Number] sayılı takas sözleşmesi'"));
		
		PrintingWordDocument(PrintFormsCollection, ObjectsArray, PrintParameters);
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "MicrosoftWordDebtAssignmentAct") Then
		PrintParameters = New Structure;
		PrintParameters.Insert("TemplateName", "PF_DOC_DebtAssignmentAct_ru");
        PrintParameters.Insert("TemplateSynonym",NStr("ru = 'Акт переуступки долга';
														|vi = 'Debt assignment protocol';
														|en = 'Debt assignment protocol'; fa = 'Debt assignment protocol';
														|it = 'Debt assignment protocol';
														|pl = 'Debt assignment protocol';
														|tr = 'Borcun nakli sözleşmesi'"));
		PrintParameters.Insert("Id","MicrosoftWordDebtAssignmentAct");
		PrintParameters.Insert("DocumentNameTemplate", 
					NStr("ru = '[Organization]-[CounterpartyDebtor]-[Creditor] Акт переуступки долга №[Number] от [Date]';
						|vi = '[Organization]-[CounterpartyDebtor]-[Creditor] Debt assignment protocol No.[Number] dated [Date]';
						|en = '[Organization]-[CounterpartyDebtor]-[Creditor] Debt assignment protocol No.[Number] dated [Date]'; fa = '[Organization]-[CounterpartyDebtor]-[Creditor] Debt assignment protocol No.[Number] dated [Date]';
						|it = '[Organization]-[CounterpartyDebtor]-[Creditor] Debt assignment protocol No.[Number] dated [Date]';
						|pl = '[Organization]-[CounterpartyDebtor]-[Creditor] Debt assignment protocol No.[Number] dated [Date]';
						|tr = '[Organization]-[CounterpartyDebtor]-[Creditor] [Date] Tarihli [Number] saylı borcun nakli sözleşmesi'"));
		
		PrintingWordDocument(PrintFormsCollection, ObjectsArray, PrintParameters);
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfAssignmentOfDebtBetweenMicrosoftWordOrganizations") Then
		PrintParameters = New Structure;
		PrintParameters.Insert("TemplateName", "PF_DOC_ActOfAssignmentOfDebtBetweenOrganizations_ru");
        PrintParameters.Insert("TemplateSynonym",NStr("ru = 'Акт переуступки долга между организациями';
														|vi = 'Debt assignment protocol intercompany';
														|en = 'Debt assignment protocol intercompany'; fa = 'Debt assignment protocol intercompany';
														|it = 'Debt assignment protocol intercompany';
														|pl = 'Debt assignment protocol intercompany';
														|tr = 'İş yerleri arasında borcun nakli sözleşmesi'"));
		PrintParameters.Insert("Id","ActOfAssignmentOfDebtBetweenMicrosoftWordOrganizations");
		PrintParameters.Insert("DocumentNameTemplate", 
					NStr("ru = '[Organization]-[CompanyCreditor] Акт переуступки долга между организациями №[Number] от [Date]';
						|vi = '[Organization]-[CompanyCreditor] Debt assignment protocol intercompany No.[Number] dated [Date]';
						|en = '[Organization]-[CompanyCreditor] Debt assignment protocol intercompany No.[Number] dated [Date]'; fa = '[Organization]-[CompanyCreditor] Debt assignment protocol intercompany No.[Number] dated [Date]';
						|it = '[Organization]-[CompanyCreditor] Debt assignment protocol intercompany No.[Number] dated [Date]';
						|pl = '[Organization]-[CompanyCreditor] Debt assignment protocol intercompany No.[Number] dated [Date]';
						|tr = '[Organization]-[CompanyCreditor] [Date]Tarihli [Number] sayılı iş yerleri arasında borcun nakli sözleşmesi'"));
		
		PrintingWordDocument(PrintFormsCollection, ObjectsArray, PrintParameters);
	EndIf;
EndProcedure

#EndRegion

#Region RegAccountingTransactions

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction


#EndRegion

#EndRegion

#Region Private

#Region Posting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure


#EndRegion

#Region Other


Procedure PrintingWordDocument(PrintFormsCollection, ObjectsArray, PrintParameters)
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, PrintParameters.Id);
	If PrintForm <> Undefined Then
		
		ObjectTemplateAndData = PrintManagement.TemplatesAndObjectsDataToPrint("Document.ARAPSettlement", 
										PrintParameters.TemplateName, ObjectsArray);
		
		OfficeDocuments = New Map;
		
		DocumentsAttributesValues = Common.ObjectsAttributesValues(ObjectsArray, 
										"Organization,CompanyCreditor,CounterpartyDebtor,Creditor,Number,Date,Ref");
		For Each Ref In ObjectsArray Do
			
			DocumentAttributesValues = DocumentsAttributesValues[Ref];
			DocumentAttributesValues.Date = Format(DocumentAttributesValues.Date, "DLF=D");
			DocumentAttributesValues.Number = ObjectsPrefixesClientServer.NumberForPrinting(DocumentAttributesValues.Number);
			DocumentName = StringFunctionsClientServer.InsertParametersIntoString(PrintParameters.DocumentNameTemplate, DocumentsAttributesValues[Ref]);
			
			If PrintParameters.Id = "MicrosoftWordOffsetAct" Then
				OfficeDocumentStorageAddress = PrintManagementTMServer.PrintingActOfDebtOffsetMicrosoftWord(Ref, ObjectTemplateAndData, PrintParameters.TemplateName);
			ElsIf PrintParameters.Id = "MicrosoftWordDebtAssignmentAct" Then
				OfficeDocumentStorageAddress = PrintManagementTMServer.PrintingActOfAssignmentOfDebtMicrosoftWord(Ref, ObjectTemplateAndData, PrintParameters.TemplateName);
			Else
				OfficeDocumentStorageAddress = PrintManagementTMServer.PrintingActOfAssignmentOfDebtBetweenMicrosoftWordOrganizations(Ref, ObjectTemplateAndData, PrintParameters.TemplateName);
			EndIf;
			
			OfficeDocuments.Insert(OfficeDocumentStorageAddress, DocumentName);
			
		EndDo;
		
		PrintForm.TemplateSynonym    = PrintParameters.TemplateSynonym;
		PrintForm.OfficeDocuments = OfficeDocuments;
		
	EndIf;
EndProcedure

#EndRegion


#EndRegion
