////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module Integration1 Document management Database functiondetermined: server, external connection
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region InterfaceImplementation

// StandardSubsystems_Print

// Overrides the list of print commands. It is called from the Print managementdetermined and is intended
// to supplement the print commands with a reconciliation sheet.
//
// Parameters:
//   FormName - String - the full name of the Form is in the form "Document._The buyer's demo order.Form.Formadocument", in which
//     print Commands are added.
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//   StandardProcessing - Boolean - If the value is set to False, the collection of print commands will not be automatically filled
//     in.
//
// Example:
//	Print Commands = Print commands.Add();
//	Print commands.Print Manager = "Processing.Integrations1documentwork3";
//	Print commands.ID = "ApprovalSheet";
//	Print commands.Presentation = NStr("ru = 'Document flow: Approval sheet'");
//	Print commands.Print verification = False;
//	Print commands.Order = 1;
//	
//	Print Commands = Print commands.Add();
//	Print commands.Print Manager = "Processing.Integrations1documentwork3";
//	Print commands.ID = "ApprovalSheetWithHistory";
//	Print commands.Presentation = NStr("ru = 'Workflow: A sheet of coordination with the history'");
//	Print commands.Print verification = False;
//	Print commands.Order = 2;
//	
//	Print Commands = Print commands.Add();
//	Print commands.Print Manager = "Processing.Integrations1documentwork3";
//	Print commands.ID = "ProtocolOfDisagreements";
//	Print commands.Presentation = NStr("ru = 'Workflow: Protocol of Disagreements'");
//	Print commands.Print verification = False;
//	Print commands.Order = 3;
//	
//	Print Commands = Print commands.Add();
//	Print commands.Print Manager = "Processing.Integrations1documentwork3";
//	Print commands.ID = "ExaminationSheet";
//	Print commands.Presentation = NStr("ru = 'Document flow: Familiarization Sheet'");
//	Print commands.Print verification = False;
//	Print commands.Order = 4;
//
Procedure BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing) Export
	
	If Constants.UseApprovalThrough1CDocumentManagement.Get() = False Then
		Return;
	EndIf;
	
	If FormName = Metadata.Catalogs.CustomerRebatesKinds.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.CustomerRebatesKinds.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Catalogs.VendorRebateKinds.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.VendorRebateKinds.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Catalogs.TermsOfSale.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.TermsOfSale.Forms.ListForm.FullName()
			Or FormName = Metadata.Catalogs.TermsOfSale.Forms.ListFormOfSpecialTermsOfSales.FullName()
			Or FormName = Metadata.Catalogs.TermsOfSale.Forms.StandardTermsOfSalesListForm.FullName()
			
			Or FormName = Metadata.Catalogs.TermsOfPurchaseFromVendors.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.TermsOfPurchaseFromVendors.Forms.ListForm.FullName()
			Or FormName = Metadata.Catalogs.LeaseContract.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.LeaseContract.Forms.ListForm.FullName()
			Or FormName = Metadata.Catalogs.CounterpartyContracts.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.CounterpartyContracts.Forms.ListForm.FullName()
			Or FormName = Metadata.Catalogs.CounterpartyContracts.Forms.PurchasingListForm.FullName()
			Or FormName = Metadata.Catalogs.CounterpartyContracts.Forms.ListFormSales.FullName()
			
			Or FormName = Metadata.Catalogs.LoanAndDepositContracts.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.LoanAndDepositContracts.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Catalogs.IntercompanyContracts.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.IntercompanyContracts.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Catalogs.AcquiringContracts.Forms.ItemForm.FullName()
			Or FormName = Metadata.Catalogs.AcquiringContracts.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.ExpenseReport.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.ExpenseReport.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.DiscrepancyReportFollowingShipment.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.DiscrepancyReportFollowingShipment.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.DiscrepancyReportFollowingShipment.Forms.SelfServiceWorkplaceListForm.FullName()
			
			Or FormName = Metadata.Documents.DiscrepancyReportFollowingTransfer.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.DiscrepancyReportFollowingTransfer.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.DiscrepancyReportFollowingReceipt.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.DiscrepancyReportFollowingReceipt.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.SalesOrder.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.SalesOrder.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.SalesOrder.Forms.DocumentsListForm.FullName()
			
			Or FormName = Metadata.Documents.DeliveryOrder.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.DeliveryOrder.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.PurchaseOrder.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.PurchaseOrder.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.PurchaseOrder.Forms.DocumentsListForm.FullName()
			Or FormName = Metadata.Documents.MaterialProviderOrder2_5.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.MaterialProviderOrder2_5.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.SubcontractOrder2_5.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.SubcontractOrder2_5.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.RequestForReturnOfGoodsFromCustomer.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.RequestForReturnOfGoodsFromCustomer.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.RequestForReturnOfGoodsFromCustomer.Forms.DocumentsListForm.FullName()
			
			Or FormName = Metadata.Documents.PaymentRequest.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.PaymentRequest.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.PaymentRequest.Forms.DocumentsListForm.FullName()
			Or FormName = Metadata.Documents.PaymentRequest.Forms.FormOfListOfRequestsForApproval.FullName()
			Or FormName = Metadata.Documents.PaymentRequest.Forms.FormOfListOfRequestsForPaymentToVendors.FullName()
			
			Or FormName = Metadata.Documents.CommercialProposalForCustomer.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.CommercialProposalForCustomer.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.InventoryConsumptionPlan.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.InventoryConsumptionPlan.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.PurchasePlan.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.PurchasePlan.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.PlanOfGoodsStock.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.PlanOfGoodsStock.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.SalesPlan.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.SalesPlan.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.SalesPlanByCategories.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.SalesPlanByCategories.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.ProductionPlan.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.ProductionPlan.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.AssemblyDisassemblyPlan.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.AssemblyDisassemblyPlan.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.EngineeringChangeOrder.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.EngineeringChangeOrder.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.CashTransferReferenceOrder.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.CashTransferReferenceOrder.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.CashTransferReferenceOrder.Forms.DocumentsListForm.FullName()
			
			Or FormName = Metadata.Documents.Trip.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.Trip.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.DebitCustomerRebates.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.DebitCustomerRebates.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.WriteOffVendorRebates.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.WriteOffVendorRebates.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.ConditionsOfCustomerRebates.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.ConditionsOfCustomerRebates.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.ConditionsOfVendorRebates.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.ConditionsOfVendorRebates.Forms.ListForm.FullName()
			
			Or FormName = Metadata.Documents.PriceSetup.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.PriceSetup.Forms.ListForm.FullName()
			Or FormName = Metadata.Documents.BudgetEntryForm.Forms.DocumentForm.FullName()
			Or FormName = Metadata.Documents.BudgetEntryForm.Forms.ListForm.FullName()
			Then
		
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		
		If Settings.UseIntegrationBefore2
				And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.8.1") Then
			
			PrintCommand = PrintCommands.Add();
			PrintCommand.PrintManager = "DataProcessor.IntegrationWith1CDocumentManagement";
			PrintCommand.Id = "PF_MXL_ApprovalForm";
			PrintCommand.Presentation = NStr("vi = '1C:Document Management: Trang thống nhất';
											|ru = 'Документооборот: Лист согласования';
											|en = 'Document management: Approval sheet'; fa = 'Document management: Approval sheet';
											|it = 'Документооборот: Лист согласования';
											|pl = 'Document management: Approval sheet';
											|tr = 'İş akışı: Mutabakat listesi'");
			PrintCommand.CheckPostingBeforePrint = False;
			PrintCommand.Order = 1;
			
		EndIf;
		
		If Settings.UseIntegrationBefore3
				And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.14.31") Then
			
			PrintCommand = PrintCommands.Add();
			PrintCommand.PrintManager = "DataProcessor.IntegrationWith1CDocumentManagement3";
			PrintCommand.Id = "ApprovalSheet";
			PrintCommand.Presentation = NStr("vi = '1C:Document Management: Trang thống nhất';
											|ru = 'Документооборот: Лист согласования';
											|en = 'Document management: Approval sheet'; fa = 'Document management: Approval sheet';
											|it = 'Документооборот: Лист согласования';
											|pl = 'Document management: Approval sheet';
											|tr = 'İş akışı: Mutabakat listesi'");
			PrintCommand.CheckPostingBeforePrint = False;
			PrintCommand.Order = 1;
			
			PrintCommand = PrintCommands.Add();
			PrintCommand.PrintManager = "DataProcessor.IntegrationWith1CDocumentManagement3";
			PrintCommand.Id = "ExaminationSheet";
			PrintCommand.Presentation = NStr("vi = '1C:Document Management: Trang tham khảo';
											|ru = 'Документооборот: Лист ознакомления';
											|en = 'Document management: Preview sheet'; fa = 'Document management: Preview sheet';
											|it = 'Документооборот: Лист ознакомления';
											|pl = 'Document management: Preview sheet';
											|tr = 'İş akışı: İnceleme listesi'");
			PrintCommand.CheckPostingBeforePrint = False;
			PrintCommand.Order = 2;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// End StandardSubsystems_Print

#EndRegion

#Region AttachedFiles

// Sets the indication of the presence of attached files UP to for the IC object. It is called when adding
// a link to a DO object that has files, when adding a file from the IC interface, and when updating in the background.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - XDTO is the type of Document flow object.
//   ObjectIS - AnyRef - the IP object.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//
Procedure OnAdd1CDocumentManagementAttachedFiles(ID, Type, ObjectIS, StandardProcessing) Export
	
	
	
EndProcedure

// Removes the indication of the presence of attached files for the IC object, if they are not in the IC itself. Called when
// the link to the object is removed BEFORE and during background updates.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - XDTO is the type of Document flow object.
//   ObjectIS - AnyRef - the IP object.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//
Procedure OnRemove1CDocumentManagementAttachedFiles(ID, Type, ObjectIS, StandardProcessing) Export
	
	
	
EndProcedure

// Called when determining the presence of files stored in the integrated configuration.
//
// Parameters:
//   FilesOwner - Arbitrary - the object is the owner.
//   HasFiles - Boolean, Undefined - an implicitly returned value, a sign of the presence of attached files.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//
Procedure WhenDeterminingPresenceOfAttachedFiles(FilesOwner, HasFiles, StandardProcessing) Export
	
	
	
EndProcedure

// Called when receiving attached files.
//
// Parameters:
//   FilesOwner - Arbitrary - the object is the owner.
//   FilesData - Array of See FilesOperations.FileData
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//
Procedure OnReceiveAttachedFiles(FilesOwner, FilesData, StandardProcessing) Export
	
	
	
EndProcedure

#EndRegion

// Called when creating 1C business process forms:Document management. Allows you to perform additional actions.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the Workflow business process.
//   Cancel - Boolean - indicates that the form was not created.
//   StandardProcessing - Boolean - standard processing when creating a form on the server.
//
Procedure AdditionalProcessingOfBusinessProcessForm(Form, Cancel, StandardProcessing) Export
	
	
	
EndProcedure

// Called when creating document forms of Document flow. Allows you to perform additional actions.
//
// Parameters:
//   Form - ClientApplicationForm - the document form of the document flow.
//   Cancel - Boolean - indicates that the form was not created.
//   StandardProcessing - Boolean - standard processing when creating a form on the server.
//
Procedure AdditionalProcessingOfDocumentForm(Form, Cancel, StandardProcessing) Export
	
	// Set access to the State field by operating mode.
	SetPrivilegedMode(True);
	If ValueIsFilled(Form.ExternalObject)
			And Constants.UseApprovalThrough1CDocumentManagement.Get() Then
		Form.Items.State.ReadOnly = True;
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure

// Called when creating a Workflow task form. Allows you to perform additional actions.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the workflow task.
//   Cancel - Boolean - indicates that the form was not created.
//   StandardProcessing - Boolean - standard processing when creating a form on the server.
//
Procedure AdditionalProcessingOfTaskForm(Form, Cancel, StandardProcessing) Export
	
	
	
EndProcedure

// Complements the correspondence table of supported types.
//
// Parameters:
//   Table - ValueTable - an implicitly returned value with columns:
//     * TypeNameXDTO - String - the name of the type XDTO.
//     * ObjectTypeIS - Type - the type of IP object.
//
// Example:
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMBankAccount", Type("Reference link._demobankovskieaccounts"));
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMMeasurementUnit", Type("Reference link._demoedits of measurement"));
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMContactPerson", Type("Reference link._democontactnyelitsa"));
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMCorrespondent", Type("Reference link._DemoContragents"));
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMProduct", Type("Reference link._DemoNomenclature"));
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMOrganization", Type("Reference link._demoorganizations"));
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMSubdivision", Type("Reference link._demo divisions"));
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMCashFlowItem", Type("Reference link._demostation of movement of monetary funds"));
//	Integration1sdocumentobase functionality.Add a line of corresponding types(
//		Table, "DMEmployee", Type("Reference link._DemoSotrudniki"));
//
Procedure CompleteTypeMatching(Table) Export
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMMeasurementUnit", Type("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMContactPerson", Type("CatalogRef.ContactPersonsForPartners"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMProduct", Type("CatalogRef.Products"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMCashFlowItem", Type("CatalogRef.CashFlowReportItems"));
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.16.33") Then
		IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
			Table, "DMVATRateUniversal", Type("CatalogRef.VATRates"));
	Else
		IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
			Table, "DMVATRate", Type("CatalogRef.VATRates"));
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMBankAccount", Type("CatalogRef.CounterpartyBankAccounts"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMBankAccount", Type("CatalogRef.CompaniesBankAccounts"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMCorrespondent", Type("CatalogRef.Counterparties"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMOrganization", Type("CatalogRef.Companies"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMPrivatePerson", Type("CatalogRef.Persons"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMSubdivision", Type("CatalogRef.BusinessStructure"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMLegalPrivatePerson", Type("EnumRef.CompanyIndividual"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMLegalPrivatePerson", Type("EnumRef.LegalEntityIndividual"));
	
	IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
		Table, "DMLegalPrivatePerson", Type("EnumRef.IndividualCompany"));
	
	
EndProcedure

// Fills in the properties of the XDTO object from the details of the consumer configuration object. By default
// , only the name and identifier are filled in. If it is necessary to ensure that other details of objects
// created by links are filled in, the corresponding properties of the XDTO object should be filled in. The same values will
// be used when searching for matches for directories that have foreign keys (INN, KPP).
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject - the object to fill in.
//   ReferenceToConsumer - AnyRef - a reference to the original consumer configuration object.
//
// Example:
//	If the integration1sdocumentobase functionality.Check the type(Proxy, ObjectXDTO, "DMCorrespondent")
//			and the type of link(referencesconsumer) = Type("Reference link._DemoContragents") Then
//		Attributes = General purpose.The values of the object's requirements (referencesconsumer, "INN, CHECKPOINT, Legal entity");
//		ObjectXDTO.inn = Attributes.INN;
//		ObjectXDTO.kpp = Attributes.CHECKPOINT;
//		If Attributes.Legal entity = Transfers._DemoIrFizFace.Legal Entity Then
//			ObjectXDTO.legalPrivatePerson = "LglPerson";
//		Inacheesli Attributes.Legal entity = Transfers._DemoIrFizFace.Physical person Then
//			ObjectXDTO.legalPrivatePerson = "Individual";
//		Inacheesli Attributes.Legal entity = Transfers._DemoIrFizFace.Individual Entrepreneur Then
//			ObjectXDTO.legalPrivatePerson = "individualentreenter";
//		If there are Attributes.Legal entity = Transfers._DemoIrFizFace.Legal Entityeresident Then
//			ObjectXDTO.legalPrivatePerson = "LglPersonNonResident";
//		The end if;
//	InachEes1 if integration1sdocumentofunctionbase functionality.Check the type(Proxy, ObjectXDTO, "DMOrganization")
//			and the type of the link(Link Consumer) = Type("Reference link._demoorganizations") Then
//		Attributes = General purpose.The values of the object's requirements (referencesconsumer, "INN, CHECKPOINT");
//		ObjectXDTO.inn = Attributes.INN;
//		ObjectXDTO.kpp = Attributes.CHECKPOINT;
//	In case of integration1documentary turnaround basefunctionality.Check the type(Proxy, ObjectXDTO, "DMBankAccount")
//			and the type of the link(Consumer link) = Type("Reference link._demobankscounts") Then
//		Attributes = General purpose.The values of the object's requestionsreferencesconsumer, "Owner, Account Number");
//		ObjectXDTO.number = Attributes.Account numbers;
//		If the HR type (Attributes.Owner) = Type("Reference link._DemoContragents") Then
//			Owner TYPEXDTO = "DMCorrespondent";
//		If there is a type of IDN (Attributes.Owner) = Type("Reference link._demoorganizations") Then
//			Type of OWNERXDTO = "DMOrganization";
//		The end if;
//		ObjectXDTO.owner = integrations1documentofunctionbase functionality.Create an object(
//			Proxy,
//			Type of OWNERXDTO,
//			Attributes.Owner);
//		If the value is filled in (Attributes.Bank) Then
//			ObjectXDTO.bank = Integration1sdocumentobase functionality.Create an object(
//				Proxy,
//				"DMBank",
//				Attributes.Bank);
//		The end if;
//	Otherwise //...
//	The end if;
//
Procedure FillInDetailsFromConsumer(Proxy, XDTODataObject, ReferenceToConsumer) Export
	
	IntegrationWith1CDocumentManagementERP.FillInDetailsFromConsumer(Proxy, XDTODataObject, ReferenceToConsumer);
	
EndProcedure

// Fills in the details of the form according to the data of the integrated system object.
//
// Parameters:
//   ExternalObject - AnyRef - reference to the base object.
//   Form - ClientApplicationForm - The integration processing form1sdocumentation corresponding
//    to the Document flow object to be filled in.
//
Procedure FillOutFormFromConsumer(ExternalObject, Form) Export
	
	
	
EndProcedure

// Called before recording incoming, outgoing, internal documents of the Document Flow.
// Allows you to perform additional checks before recording, and refuse to record.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject - the object being filled in. Type DMInternalDocument, DMIncomingDocument, DMOutgoingDocument.
//   Form - ClientApplicationForm - the document form of the document flow.
//   Cancel - Boolean - indicates that the document was not recorded.
//
Procedure BeforeWritingDocument(Proxy, XDTODataObject, Form, Cancel) Export
	
	
	
EndProcedure

// It is called before recording objects of the integrated system through the exchange mechanism with 1C:Document flow.
// Allows you to perform additional checks before recording, change additional properties and refuse recording.
//
// Parameters:
//   ObjectIS - DocumentObject
//            - CatalogObject - the IS object being modified.
//   Cancel - Boolean - indicates that the recording was rejected.
//   Var_DocumentWriteMode - DocumentWriteMode - allows you to change the recording mode.
//   Var_DocumentPostingMode - DocumentPostingMode - allows you to change the mode of the document.
//
Procedure BeforeRecordingICObject(ObjectIS, Cancel,
		Var_DocumentWriteMode = Undefined, Var_DocumentPostingMode = Undefined) Export
	
	If (TypeOf(ObjectIS) = Type("DocumentObject.ConditionsOfCustomerRebates")
				Or TypeOf(ObjectIS) = Type("DocumentObject.ConditionsOfVendorRebates"))
			And Constants.UseApprovalThrough1CDocumentManagement.Get() Then
		ObjectIS.AdditionalProperties.Insert("SkipCheckingChangesByStatus", True);
	EndIf;
	
	
EndProcedure

// Called when adding a subsystem to the tree of integrated objects, with which
// integration is configured. By default, the first-level subsystems included in the command interface and
// subordinate to them are displayed.
//
// Parameters:
//   Subsystem - MetadataObject - a subsystem to be added that contains the objects to be integrated.
//   Cancel - Boolean - when set to False, the subsystem will be skipped along with all subordinates.
//
Procedure WhenAddingSubsystemToTreeOfIntegrableObjects(Subsystem, Cancel) Export
	
	If Subsystem.Name = "SalesBasic" Or Subsystem.Name = "PurchasesBasic" Then
		Cancel = True;
	EndIf;
	
	If Subsystem.Name = Metadata.Subsystems.CRMAndMarketing.Subsystems.CustomerRebates.Name
			And Not GetFunctionalOption("UseCustomerRebates") Then
		Cancel = True;
	EndIf;
	
	If Subsystem.Name = Metadata.Subsystems.Purchases.Subsystems.VendorRebates.Name
			And Not GetFunctionalOption("UseVendorRebates") Then
		Cancel = True;
	EndIf;
	
EndProcedure

// Called when writing the constants of the subsystem Integration with 1C:Document management.
//
// Parameters:
//   Source - ConstantValueManager - a recordable constant.
//   Cancel - Boolean - the flag for refusing to perform the recording.
//
Procedure WhileSavingConstant(Source, Cancel) Export
	
	
	
EndProcedure

// Fills in the collection of printed forms of an object by the name of the print manager and the print manager's command.
//
// Parameters:
//   ExternalObject - AnyRef - external object.
//   CommandName - String - command name.
//   AdditionalParameters - String - (optional) custom parameters to pass to the print Manager.
//   PrintFormsCollection - ValueTable - an implicitly returned value.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//
Procedure WhenFillingOutCollectionOfPrintedForms(ExternalObject, CommandName, AdditionalParameters, PrintFormsCollection,
		StandardProcessing) Export
	
	
	
EndProcedure

// Called when filling in the property of the XDTO object by the value in the IC (for example, by the value of the props of the IC object).
//
// Parameters:
//   Value - Arbitrary - the value that is used to fill in the properties of the XDTO object to be passed to BEFORE.
//   Properties - ClientApplicationForm
//            - ValueTableRow - the data set to be filled in, which will be filled in with the XDTO object for Transferring to the DO.
//            - See IntegrationWith1CDocumentManagement.StructureOfTheAttributesOfTheFilledObjectDM
//   ObjectType - String - the type of object to be filled in, for example, "DMInternalObject".
//   PropertyName - String - the name of the property to be filled in, for example, "Counterparty", "State of agreement".
//   PropertyType1 - String - the type of the property to be filled in, for example, "DMCorrespondent", "DMDocumentStatus".
//   StandardProcessing - Boolean - an implicitly returned value, a sign that the standard filling
//     of the property by the value of the value will not be performed.
//
// Example:
//	If Property Type = "DMDocumentStatus" And Property Name = "Statesconformance" Then
//		If The Value Is = Enumeration._The state of the buyer's order.Agreed Then
//			Properties[Property Name] = "Approved";
//			Standard processing = Lies;
//		The end if;
//	The end if;
//
Procedure WhenFillingInXDTOObjectPropertyByValue(Value, Properties, ObjectType, PropertyName, PropertyType1,
		StandardProcessing) Export
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If Not Settings.UseIntegrationBefore2 Then
		Return;
	EndIf;
	
	If PropertyType1 = "DMVATRate" And PropertyName = "VATRate" Then
		
		VATRate = "";
		VATRateID = "";
		
		
		If TypeOf(Value) = Type("CatalogRef.VATRates") Then
			If Value = Catalogs.VATRates.EXCLUDINGVAT Then
				VATRate = NStr("vi = 'Không gồm thuế GTGT';
								|ru = 'Без НДС';
								|en = 'Excluding VAT'; fa = 'بدون مالیات بر ارزش افزوده';
								|it = 'IVA esclusa';
								|pl = 'Netto';
								|tr = 'KDV hariç'");
				VATRateID = "БезНДС"; //@NON-NLS-1
			Else
				Rate1 = Common.ObjectAttributeValue(Value, "Rate1");
				If Rate1 = 0 Then
					VATRate = "0%";
					VATRateID = "НДС0"; //@NON-NLS-1
				ElsIf Rate1 = 5 Then
					VATRate = "5%";
					VATRateID = "НДС5"; //@NON-NLS-1
				ElsIf Rate1 = 7 Then
					VATRate = "7%";
					VATRateID = "НДС7"; //@NON-NLS-1
				ElsIf Rate1 = 10 Then
					VATRate = "10%";
					VATRateID = "НДС10"; //@NON-NLS-1
				ElsIf Rate1 = 18 Then
					VATRate = "18%";
					VATRateID = "НДС18"; //@NON-NLS-1
				ElsIf Rate1 = 20 Then
					VATRate = "20%";
					VATRateID = "НДС20"; //@NON-NLS-1
				ElsIf Rate1 = 22 Then
					VATRate = "22%";
					VATRateID = "НДС22"; //@NON-NLS-1
				EndIf;
			EndIf;
		EndIf;
		
		If VATRate <> "" And VATRateID <> "" Then
			Properties.VATRate = VATRate;
			Properties.VATRateID = VATRateID;
			Properties.VATRateType = "DMVATRate";
			StandardProcessing = False;
		EndIf;
		
	EndIf;
	
	If PropertyType1 = "DMDocumentStatus" And PropertyName = "StateApproval" Then
		
		// Selection of enumeration values-approval statuses according to the approval status BEFORE.
		If Value = Enums.StatusesOfCommercialProposalsForCustomers.Valid
				Or Value = Enums.CounterpartyContractStatuses.Valid
				Or Value = Enums.StatusesOfTermsOfSales.Valid
				Or Value = Enums.StatusesOfTermsOfPurchase.Valid
				Or Value = Enums.SalesOrderStatuses.ToSupply
				Or Value = Enums.PurchaseOrderStatuses.Approved
				Or Value = Enums.StatusesOfDiscrepancyReport.Approved
				Or Value = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply
				Or Value = Enums.StatusesOfPaymentRequests.AgreedUpon
				Or Value = Enums.CashTransferOrderStatuses.Approved
				Or Value = Enums.ProductPricingStatuses.Approved Then
			Properties.StateApproval = NStr("vi = 'Đã thống nhất';
											|ru = 'Согласован';
											|en = 'Approved'; fa = 'تأییدشده';
											|it = 'Concordato';
											|pl = 'Uzgodniony';
											|tr = 'Onaylandı'");
			Properties.StateApprovalID = "Согласован"; //@NON-NLS-1
			Properties.StateApprovalType = "DMDocumentStatus";
			StandardProcessing = False;
			
		ElsIf Value = Enums.StatusesOfCommercialProposalsForCustomers.NotApproved
				Or Value = Enums.CounterpartyContractStatuses.NotApproved
				Or Value = Enums.StatusesOfTermsOfPurchase.NotApproved
				Or Value = Enums.StatusesOfTermsOfSales.NotApproved
				Or Value = Enums.SalesOrderStatuses.NotApproved
				Or Value = Enums.PurchaseOrderStatuses.NotApproved
				Or Value = Enums.StatusesOfDiscrepancyReport.NotApproved
				Or Value = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon
				Or Value = Enums.StatusesOfPaymentRequests.IsRejected
				Or Value = Enums.CashTransferOrderStatuses.TurnDown
				Or Value = Enums.ProductPricingStatuses.NotApproved Then
			Properties.StateApproval = NStr("vi = 'Không thống nhất';
											|ru = 'Не согласован';
											|en = 'Not approved'; fa = 'تأییدنشده';
											|it = 'Non concordato';
											|pl = 'Nieuzgodniony';
											|tr = 'Onaylanmadı'");
			Properties.StateApprovalID = "НеСогласован"; //@NON-NLS-1
			Properties.StateApprovalType = "DMDocumentStatus";
			StandardProcessing = False;
			
		ElsIf Value = Enums.StatusesOfPaymentRequests.NotAgreedUpon
				Or Value = Enums.CashTransferOrderStatuses.NotApproved Then
			Properties.StateApproval = NStr("vi = 'Cần thống nhất';
											|ru = 'На согласовании';
											|en = 'Pending approval'; fa = 'در انتظار تأیید';
											|it = 'In fase di definizione';
											|pl = 'Na uzgodnieniu';
											|tr = 'Onay bekliyor'");
			Properties.StateApprovalID = "НаСогласовании"; //@NON-NLS-1
			Properties.StateApprovalType = "DMDocumentStatus";
			StandardProcessing = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Retrieves a table of object form print managers.
//
// Parameters:
//   ObjectManager - String - the full name of the metadata of the object manager.
//   PrintForms - ValueTable:
//     * PrintManager - String - the name of the object whose manager module contains
//                                 the Print procedure that generates tabular documents for this command.
//     * CommandName - String
//     * CommandPresentation - String
//     * AdditionalParameters - String - (optional) custom parameters to pass to the print Manager.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//
// Example:
//	Print Commands = Integrations1documentobase functionality.Form Print Commands(
//		Object Manager + ".The form.Subscription Form");
//	
//	For Each Command From The Print Command Cycle
//		String = Printable forms.Add();
//		Line.Print Managers = The team.Print Managers;
//		Line.Teamname = The team.ID;
//		Line.Team Introduction = The team.Presentation;
//	The end of the cycle;
//
Procedure WhenFillingInObjectPrintManagerTable(ObjectManager, PrintForms, StandardProcessing) Export
	
	StandardProcessing = False;
	
	Exceptions = New Array;
	Exceptions.Add("MicrosoftWordAct");
	Exceptions.Add("ListOfMSWordEnumerations");
	Exceptions.Add("ListOfOOWriterEnumerations");
	Exceptions.Add("T53MSWord");
	Exceptions.Add("T53OOWriter");
	Exceptions.Add("MicrosoftWordOffsetAct");
	Exceptions.Add("MicrosoftWordDebtAssignmentAct");
	Exceptions.Add("MicrosoftWordCommercialOffer");
	Exceptions.Add("CommercialOfferOpenOfficeOrgWriter");
	Exceptions.Add("MicrosoftWordQuestionnaire");
	Exceptions.Add("OpenOfficeOrgWriterQuestionnaire");
	Exceptions.Add("LabelStorageCells");
	Exceptions.Add("ItemsBatchLabel");
	Exceptions.Add("ShippingLabel");
	Exceptions.Add("PriceTagProducts");
	Exceptions.Add("LabelProducts_");
	Exceptions.Add("RetailRevaluation");
	Exceptions.Add("PriceSetup");
	Exceptions.Add("GoodsCodes");
	Exceptions.Add("INV3");
	Exceptions.Add("INV19");
	Exceptions.Add("OperationSheet");
	Exceptions.Add("MSWordDismissalOrder");
	Exceptions.Add("OrderToTranslateMSWord");
	Exceptions.Add("OrderOfEmploymentOfMSWord");
	Exceptions.Add("OrderToGrantLeaveMSWord");
	Exceptions.Add("SetOfDocuments");
	Exceptions.Add("SetOfDocumentsWithSettings");
	
	PrintCommands = IntegrationWith1CDocumentManagementCore.FormPrintCommands(
		ObjectManager + ".Form.ListForm");
	
	For Each PrintCommand In PrintCommands Do
		If Exceptions.Find(PrintCommand.Id) = Undefined
				And ValueIsFilled(PrintCommand.PrintManager) Then
			IntegrationWith1CDocumentManagementCore.AddPrintCommand(PrintForms, PrintCommand);
		EndIf;
	EndDo;
	
EndProcedure

// Called when filling out the form of the object BEFORE when it is created based on the IC object. Allows you to replenish the object
// UP to in a way not supported by the integration rules.
//
// Parameters:
//   ObjectIS - Arbitrary - reference to the IP object.
//   Form - ClientApplicationForm - the form of the 1C object:Document management.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the applicable rule.
//
Procedure OnFillFormOfTheObjectDMByObjectIS(ObjectIS, Form, Rule) Export
	
	
	
EndProcedure

// Called when the state of the agreement changes to BEFORE. It is intended for changing the agreed object.
//
// Parameters:
//   SubjectOfApproval - AnyRef - a consistent object.
//   State - EnumRef.ApprovalStatesIn1CDocumentManagement
//   CallingFromObjectForm - Boolean - True if the state change is caused by the user from the object form.
//   Set - String - a representation of the user who has set the new state.
//   InstallationDate - Date - The date when the new state was set.
//
// Example:
//	If the call is from the object form then
//		Refund;
//	The end if;
//	
//	If the type of VHF(Subject of Agreement) = Type("Document Link.Buyer's _democorder") Then
//	
//		Object = Subject of agreement.Get an object();
//		If State = Enumeration.States of agreement in document flow.Upon Agreement Then
//			Object.State = Enumeration._The state of the buyer's order.Agreement;
//		And if the State = Enumeration.States of agreement in document flow.Inconsistent Then
//			Object.State = Enumeration._The state of the buyer's order.Inconsistent;
//		And if the State = Enumeration.States of agreement in document flow.Agreed Then
//			Object.State = Enumeration._The state of the buyer's order.Agreed;
//		Otherwise
//			Object.State = Enumeration._The state of the buyer's order.Prepared by;
//		The end if;
//		Object.Record(Document recording mode.Recording);
//	
//	The end if;
//
Procedure WhenApprovalStateChanges(SubjectOfApproval, State, CallingFromObjectForm, Set,
		InstallationDate) Export
	
	StateOfApplicationUH = "";
	If State = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
		StateOfApplicationUH = "AwaitingConfirmation";
	ElsIf State = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
		StateOfApplicationUH = "IsRejected";
	ElsIf State = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
		StateOfApplicationUH = "Upholded_";
	EndIf;
	
	If Common.SubsystemExists("ПодсистемыУХ") And ValueIsFilled(StateOfApplicationUH) Then
		EnumerationName = "ApprovalStates";
		RegisterName = "ObjectStatesRegister";
		TypesOfApplications = Metadata.InformationRegisters[RegisterName].Dimensions.Object.Type.Types();
		If TypesOfApplications.Find(TypeOf(SubjectOfApproval)) <> Undefined Then
			ModuleProcessesAndApprovalManagementCPM = Common.CommonModule("УправлениеПроцессамиСогласованияУХ");
			Try
				ModuleProcessesAndApprovalManagementCPM.ChangeRequestStateToArbitrary(
					SubjectOfApproval,
					Enums[EnumerationName][StateOfApplicationUH]);
			Except
				IntegrationWith1CDocumentManagementCore.WriteError(
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
	EndIf;

	If CallingFromObjectForm Then
		Return;
	EndIf;
	
	ObjectType = TypeOf(SubjectOfApproval);
	If ObjectType <> Type("DocumentRef.CommercialProposalForCustomer")
			And ObjectType <> Type("DocumentRef.SalesOrder")
			And ObjectType <> Type("DocumentRef.PurchaseOrder")
			And ObjectType <> Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
			And ObjectType <> Type("DocumentRef.PriceSetup")
			And ObjectType <> Type("DocumentRef.DiscrepancyReportFollowingShipment")
			And ObjectType <> Type("DocumentRef.DiscrepancyReportFollowingTransfer")
			And ObjectType <> Type("DocumentRef.DiscrepancyReportFollowingReceipt")
			And ObjectType <> Type("DocumentRef.PaymentRequest")
			And ObjectType <> Type("DocumentRef.CashTransferReferenceOrder")
			And ObjectType <> Type("DocumentRef.ConditionsOfCustomerRebates")
			And ObjectType <> Type("DocumentRef.ConditionsOfVendorRebates")
			And ObjectType <> Type("DocumentRef.DebitCustomerRebates")
			And ObjectType <> Type("DocumentRef.WriteOffVendorRebates")
			And ObjectType <> Type("DocumentRef.EngineeringChangeOrder")
			And ObjectType <> Type("CatalogRef.CustomerRebatesKinds")
			And ObjectType <> Type("CatalogRef.VendorRebateKinds")
			And ObjectType <> Type("CatalogRef.CounterpartyContracts")
			And ObjectType <> Type("CatalogRef.TermsOfSale")
			And ObjectType <> Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		Return;
	EndIf;
	
	Rules = New Array;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If Settings.UseIntegrationBefore2 Then
		TableName = "Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesIS";
		ModuleIntegrationWith1CDocumentManagementServerCall = Common.CommonModule(
			"IntegrationWith1CDocumentManagementServerCall");
		SuitableRules = ModuleIntegrationWith1CDocumentManagementServerCall.SuitableRules(SubjectOfApproval);
		For Each String In SuitableRules Do
			Rules.Add(String.Ref);
		EndDo;
	ElsIf Settings.UseIntegrationBefore3 Then
		TableName = "Catalog.RulesForIntegrationWith1CDocumentManagement3.AttributeFillingRulesIS";
		ModuleIntegrationWith1CWorkflow3ServerCall = Common.CommonModule(
			"IntegrationWith1CDocumentManagement3ServerCall");
		Rules = ModuleIntegrationWith1CWorkflow3ServerCall.SuitableObjectIntegrationRules(
			SubjectOfApproval,
			True);
	EndIf;
	
	If Rules.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query(
		"SELECT DISTINCT
		|	AttributeFillingRulesIS.AttributeNameObjectIS AS AttributeNameObjectIS,
		|	AttributeFillingRulesIS.ModeOfChangingTheDataOfThePostedDocument AS ModeOfChangingTheDataOfThePostedDocument
		|FROM
		|	&TableName AS AttributeFillingRulesIS
		|WHERE
		|	AttributeFillingRulesIS.Ref IN(&Rules)
		|	AND (AttributeFillingRulesIS.AttributeNameObjectDM = ""statusApproval""
		|			OR (CAST(AttributeFillingRulesIS.AttributeNameObjectDM AS STRING(7))) = ""status_"")
		|	AND AttributeFillingRulesIS.ShouldUpdate = TRUE");
	Query.Text = StrReplace(Query.Text, "&TableName", TableName);
	Query.SetParameter("Rules", Rules);
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	ObjectIS = SubjectOfApproval.GetObject();
	ObjectIS.Lock();
	
	HasChanges = False;
	RequiresRecheck = False;
	IsDocument = Common.IsDocument(ObjectIS.Metadata());
	
	For Each IPObjectAttributes In Result.Unload() Do
		
		If IsDocument And ObjectIS.Posted
				And IPObjectAttributes.ModeOfChangingTheDataOfThePostedDocument =
					Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited Then
			Continue;
		EndIf;
		
		CurrentValue = ObjectIS[IPObjectAttributes.AttributeNameObjectIS];
		AttributeType = TypeOf(CurrentValue);
		NewValue = IntegrationWith1CDocumentManagementERP.StateOfERPApproval(
			AttributeType,
			IPObjectAttributes.AttributeNameObjectIS,
			TypeOf(ObjectIS),
			State);
		If ValueIsFilled(NewValue) And CurrentValue <> NewValue Then
			ObjectIS[IPObjectAttributes.AttributeNameObjectIS] = NewValue;
			HasChanges = True;
			If IPObjectAttributes.ModeOfChangingTheDataOfThePostedDocument =
					Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting Then
				RequiresRecheck = True;
			EndIf;
		EndIf;
		
	EndDo;
	
	If HasChanges Then
		
		If RequiresRecheck Then
			
			Cancel = False;
			WriteMode = DocumentWriteMode.Posting;
			PostingMode = DocumentPostingMode.Regular;
			IntegrationWith1CDocumentManagementCoreOverridable.BeforeRecordingICObject(
				ObjectIS,
				Cancel,
				WriteMode,
				PostingMode);
			If Not Cancel Then
				ObjectIS.Write(WriteMode, PostingMode);
			EndIf;
			
		Else
			
			ObjectIS.DataExchange.Load = True;
			
			Cancel = False;
			IntegrationWith1CDocumentManagementCoreOverridable.BeforeRecordingICObject(
				ObjectIS,
				Cancel);
			If Not Cancel Then
				ObjectIS.Write();
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ObjectIS.Unlock();
	
EndProcedure

// Additional processing of the XDTO message.
//
// Parameters:
//   Message - XDTODataObject - the XDTO object, a descendant of DMILRequest.
//   Result - XDTODataObject - an implicit return value. The XDTO object,
//     a descendant of DMILResponse, if the message is considered processed.
//             - Undefined - if the message requires further processing.
//
Procedure WhenProcessingUniversalMessage(Message, Result) Export
	
	
	
EndProcedure

// Called when filling in the details of the IP object by the value of the object's details BEFORE. When setting
// the Result parameter to a value other than Undefined, standard filling is not performed.
//
// Parameters:
//   Result - Arbitrary - the filled-in value of the IP object's props.
//   ValueToFillIn - XDTODataObject - the source object to match.
//                         - See IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject
//   ObjectAttributeTypeIS - Type - the type of the IP object's details to be filled in.
//   AttributeNameObjectIS - String - name of the IP object Attribute to be filled in.
//   TypeOfIPObjectToFillIn - Type - the type of the IP object to be filled in.
//   ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//   IsAdditionalAttributeIS - Boolean - true if the Attribute of the IP object to be filled in is an additional one. a property.
//   AdditionalAttributeIS - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - the property is the owner.
//   ChoiceParameters - Map of KeyAndValue - The selection parameters:
//     * Key - String - the name of the parameter of the type "Selection.The owner."
//     * Value - Arbitrary - the value of the parameter (selection).
//
// Example:
//	If the object's Request typeis = Type("Boolean") And the name of the requesitaobject is = "Agreed" Then
//		If the type of the block (value to fill in) = Type("Structure") Then
//			Result = (Fill-in value.Property value = "Approved");
//		Otherwise
//			Result = (ObjectXDTO.ObjectId.ID = "Agreed");
//		The end if;
//	The end if;
//	If the type of the requesitaobject is Type("Reference Link._demoedits of measurement")
//			And the type of the ID(value for filling in) = Type("ObjectXDTO") Then
//		Result = Integration1 and document turnaround Database functionality.Find a Name(
//			Catalogs._Measurement demounits,
//			Values to fill in.name,
//			The Truth,,
//			Parameterselection["Selection.Owner"]);
//	The end if;
//	If the object's Request typeis = Type("Reference Link._demobankovskieaccounts")
//			And integration1sdocumentoworksbazofunctionality.Property set (Fill-in value, "number") Then
//		Request = New Request (
//			"SELECT THE FIRST 1
//			|T Link
//			|FROM
//			|TTHE source code._demobankscounts
//			|WHERE
//			|T Account number = &Account number");
//		Request.Set the parameter ("Account number", the value for filling.number);
//		Selection = Request.Execute().Select();
//		If the Selection.Next() Then
//			Result = Sample.Link;
//		The end if;
//	The end if;
//
Procedure WhenDeterminingValueOfPropsOnXDTOObject(Result, ValueToFillIn, ObjectAttributeTypeIS,
		AttributeNameObjectIS, TypeOfIPObjectToFillIn, ObjectToFillInIS, IsAdditionalAttributeIS = False,
		AdditionalAttributeIS = Undefined, ChoiceParameters = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If ObjectAttributeTypeIS = Type("EnumRef.CompanyIndividual") Then
		
		If IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(Proxy, ValueToFillIn) Then
			
			If ValueToFillIn.objectID.ID = "Entity" Then
				Result = Enums.CompanyIndividual.BusinessEntity;
				
			ElsIf ValueToFillIn.objectID.ID = "LegalEntityNonResident" Then
				Result = Enums.CompanyIndividual.BusinessEntity;
				
			ElsIf ValueToFillIn.objectID.ID = "Person" Then
				Result = Enums.CompanyIndividual.Individual;
				
			ElsIf ValueToFillIn.objectID.ID = "IndividualEntrepreneur" Then
				Result = Enums.CompanyIndividual.Individual;
				
			EndIf;
			
		ElsIf TypeOf(ValueToFillIn) = Type("Structure") Then
			
			If ValueToFillIn.PropertyValue = "LglPerson" Then
				Result = Enums.CompanyIndividual.BusinessEntity;
				
			ElsIf ValueToFillIn.PropertyValue = "LglPersonNonResident" Then
				Result = Enums.CompanyIndividual.BusinessEntity;
				
			ElsIf ValueToFillIn.PropertyValue = "Individ" Then
				Result = Enums.CompanyIndividual.Individual;
				
			ElsIf ValueToFillIn.PropertyValue = "IndividualEntrepreneur" Then
				Result = Enums.CompanyIndividual.Individual;
				
			EndIf;
			
		Else
			
			Return;
			
		EndIf;
		
	EndIf;
	
	If ObjectAttributeTypeIS = Type("EnumRef.LegalEntityIndividual") Then
		
		If IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(Proxy, ValueToFillIn) Then
			
			If ValueToFillIn.objectID.ID = "Entity" Then
				Result = Enums.LegalEntityIndividual.Entity;
				
			ElsIf ValueToFillIn.objectID.ID = "LegalEntityNonResident" Then
				Result = Enums.LegalEntityIndividual.LegalEntityNonResident;
				
			ElsIf ValueToFillIn.objectID.ID = "Person" Then
				Result = Enums.LegalEntityIndividual.Person;
				
			ElsIf ValueToFillIn.objectID.ID = "IndividualEntrepreneur" Then
				Result = Enums.LegalEntityIndividual.IndividualEntrepreneur;
				
			EndIf;
			
		ElsIf TypeOf(ValueToFillIn) = Type("Structure") Then
			
			If ValueToFillIn.PropertyValue = "LglPerson" Then
				Result = Enums.LegalEntityIndividual.Entity;
				
			ElsIf ValueToFillIn.PropertyValue = "LglPersonNonResident" Then
				Result = Enums.LegalEntityIndividual.LegalEntityNonResident;
				
			ElsIf ValueToFillIn.PropertyValue = "Individ" Then
				Result = Enums.LegalEntityIndividual.Person;
				
			ElsIf ValueToFillIn.PropertyValue = "IndividualEntrepreneur" Then
				Result = Enums.LegalEntityIndividual.IndividualEntrepreneur;
				
			EndIf;
			
		Else
			
			Return;
			
		EndIf;
		
	EndIf;
	
	If ObjectAttributeTypeIS = Type("EnumRef.IndividualCompany") Then
		
		If IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(Proxy, ValueToFillIn) Then
			
			If ValueToFillIn.objectID.ID = "Entity" Then
				Result = Enums.IndividualCompany.Company;
				
			ElsIf ValueToFillIn.objectID.ID = "LegalEntityNonResident" Then
				Result = Enums.IndividualCompany.Company;
				
			ElsIf ValueToFillIn.objectID.ID = "Person" Then
				Result = Enums.IndividualCompany.Person_;
				
			ElsIf ValueToFillIn.objectID.ID = "IndividualEntrepreneur" Then
				Result = Enums.IndividualCompany.Person_;
				
			EndIf;
			
		ElsIf TypeOf(ValueToFillIn) = Type("Structure") Then
			
			If ValueToFillIn.PropertyValue = "LglPerson" Then
				Result = Enums.IndividualCompany.Company;
				
			ElsIf ValueToFillIn.PropertyValue = "LglPersonNonResident" Then
				Result = Enums.IndividualCompany.Company;
				
			ElsIf ValueToFillIn.PropertyValue = "Individ" Then
				Result = Enums.IndividualCompany.Person_;
				
			ElsIf ValueToFillIn.PropertyValue = "IndividualEntrepreneur" Then
				Result = Enums.IndividualCompany.Person_;
				
			EndIf;
			
		Else
			
			Return;
			
		EndIf;
		
	EndIf;
	
	
	If ObjectAttributeTypeIS = Type("CatalogRef.VATRates") Then
		
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ValueToFillIn, "DMVATRateUniversal") Then
			
			Result = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
				ValueToFillIn.objectID.ID,
				ValueToFillIn.objectID.type,
				ObjectAttributeTypeIS);
			
			If Result = Undefined Then
				
				// It is possible that the matches were created by data synchronization and inherited identifiers.
				RefByUUID = Catalogs.VATRates.GetRef(
					New UUID(ValueToFillIn.objectID.ID));
				
				// An RLS exception is possible.
				Query = New Query(
					"SELECT ALLOWED TOP 1
					|	VATRates.Ref AS Ref
					|FROM
					|	Catalog.VATRates AS VATRates
					|WHERE
					|	VATRates.Ref = &RefByUUID");
				Query.SetParameter("RefByUUID", RefByUUID);
				
				Selection = Query.Execute().Select();
				If Selection.Next() Then
					
					// The VAT rate was found.
					Result = Selection.Ref;
					
				Else
					
					
					If Not ValueIsFilled(Result)
							And IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "name")
							And ValueToFillIn.name <> "" Then
						
						// Let's continue the search.
						Rate1 = 0;
						If IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "rate") Then
							Rate1 = ValueToFillIn.rate;
						EndIf;
						CalculatedRate = False;
						If IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "calculatedRate") Then
							CalculatedRate = ValueToFillIn.calculatedRate;
						EndIf;
						Country = Undefined;
						If IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "country") Then
							Country = IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
								Type("CatalogRef.WorldCountries"),
								IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(
									ValueToFillIn.country));
						EndIf;
						
						Query = New Query(
							"SELECT ALLOWED
							|	VATRates.Ref AS Ref
							|FROM
							|	Catalog.VATRates AS VATRates
							|WHERE
							|	VATRates.Rate1 = &Rate1
							|	AND VATRates.CalculatedRate = &CalculatedRate
							|	AND VATRates.Country = &Country
							|	AND NOT VATRates.DeletionMark");
						Query.SetParameter("Rate1", Rate1);
						Query.SetParameter("CalculatedRate", CalculatedRate);
						
						If ValueIsFilled(Country) Then
							Query.SetParameter("Country", Country);
						Else
							Query.Text = StrReplace(
								Query.Text,
								"AND VATRates.Country = &Country",
								"AND (VATRates.Country = VALUE(Catalog.WorldCountries.Russia)
								|	OR VATRates.Country = VALUE(Catalog.WorldCountries.EmptyRef))");
						EndIf;
						
						Selection = Query.Execute().Select();
						If Selection.Next() Then
							// The VAT rate was found.
							Result = Selection.Ref;
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		Else
			
			Result = Catalogs.VATRates.EmptyRef();
			
			
		EndIf;
		
	EndIf;
	
	If ObjectAttributeTypeIS = Type("CatalogRef.Counterparties")
			And IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(Proxy, ValueToFillIn) Then
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "correspondent") Then
			CounterpartyXDTO = ValueToFillIn.correspondent;
		Else
			CounterpartyXDTO = ValueToFillIn;
		EndIf;
		
		Result = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
			CounterpartyXDTO.objectID.ID,
			CounterpartyXDTO.objectID.type,
			ObjectAttributeTypeIS);
		
		If Result = Undefined Then
			
			// It is possible that the matches were created by data synchronization and inherited identifiers.
			RefByUUID = Catalogs.Counterparties.GetRef(
				New UUID(CounterpartyXDTO.objectID.ID));
			
			// An RLS exception is possible.
			Query = New Query(
				"SELECT ALLOWED TOP 1
				|	Counterparties.Ref AS Ref
				|FROM
				|	Catalog.Counterparties AS Counterparties
				|WHERE
				|	Counterparties.Ref = &RefByUUID");
			Query.SetParameter("RefByUUID", RefByUUID);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				// The counterparty has been found.
				Result = Selection.Ref;
				
			ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(CounterpartyXDTO, "name")
					And CounterpartyXDTO.name <> "" Then
				
				// We will continue the search by INN/CHECKPOINT.
				Description = CounterpartyXDTO.name;
				TIN = "";
				CRTR = "";
				
				If IntegrationWith1CDocumentManagementCore.PropertySet(CounterpartyXDTO, "inn") Then
					TIN = CounterpartyXDTO.inn;
				EndIf;
				If IntegrationWith1CDocumentManagementCore.PropertySet(CounterpartyXDTO, "kpp") Then
					CRTR = CounterpartyXDTO.kpp;
				EndIf;
				
				Query = New Query(
					"SELECT ALLOWED
					|	Counterparties.Ref AS Ref,
					|	0 AS Priority
					|FROM
					|	Catalog.Counterparties AS Counterparties
					|WHERE
					|	&TIN <> """"
					|	AND &CRTR <> """"
					|	AND Counterparties.TIN = &TIN
					|	AND Counterparties.CRTR = &CRTR
					|	AND NOT Counterparties.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Counterparties.Ref,
					|	1
					|FROM
					|	Catalog.Counterparties AS Counterparties
					|WHERE
					|	&TIN <> """"
					|	AND (&CRTR = """"
					|			OR Counterparties.CRTR = """")
					|	AND Counterparties.TIN = &TIN
					|	AND Counterparties.Description = &Description
					|	AND NOT Counterparties.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Counterparties.Ref,
					|	2
					|FROM
					|	Catalog.Counterparties AS Counterparties
					|WHERE
					|	&CRTR <> """"
					|	AND (&TIN = """"
					|			OR Counterparties.TIN = """")
					|	AND Counterparties.CRTR = &CRTR
					|	AND Counterparties.Description = &Description
					|	AND NOT Counterparties.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Counterparties.Ref,
					|	3
					|FROM
					|	Catalog.Counterparties AS Counterparties
					|WHERE
					|	&TIN <> """"
					|	AND (&CRTR = """"
					|			OR Counterparties.CRTR = """")
					|	AND Counterparties.TIN = &TIN
					|	AND NOT Counterparties.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Counterparties.Ref,
					|	4
					|FROM
					|	Catalog.Counterparties AS Counterparties
					|WHERE
					|	(&TIN = """"
					|			OR Counterparties.TIN = """")
					|	AND (&CRTR = """"
					|			OR Counterparties.CRTR = """")
					|	AND Counterparties.Description = &Description
					|	AND NOT Counterparties.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Counterparties.Ref,
					|	5
					|FROM
					|	Catalog.Counterparties AS Counterparties
					|WHERE
					|	Counterparties.Description = &Description
					|	AND (Counterparties.TIN <> """"
					|			OR Counterparties.CRTR <> """")
					|	AND NOT Counterparties.DeletionMark
					|
					|ORDER BY
					|	Priority");
				Query.SetParameter("TIN", TIN);
				Query.SetParameter("CRTR", CRTR);
				Query.SetParameter("Description", Description);
				
				Selection = Query.Execute().Select();
				If Selection.Next() Then
					If Selection.Priority < 5 Then
						// The counterparty has been found.
						Result = Selection.Ref;
					Else
						// If the names of the counterparties match, but the TIN/KPP differ, you need
						// to create a new counterparty.
						Result = IntegrationWith1CDocumentManagementCore.NewObjectIsFromXDTOObject(
							Metadata.Catalogs.Counterparties,
							CounterpartyXDTO,
							ObjectToFillInIS,
							RefByUUID);
					EndIf;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ObjectAttributeTypeIS = Type("CatalogRef.Companies")
			And IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(Proxy, ValueToFillIn) Then
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "organization") Then
			XDTOOrganization = ValueToFillIn.organization;
		Else
			XDTOOrganization = ValueToFillIn;
		EndIf;
		
		Result = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
			XDTOOrganization.objectID.ID,
			XDTOOrganization.objectID.type,
			ObjectAttributeTypeIS);
		
		If Result = Undefined Then
			
			// It is possible that the matches were created by data synchronization and inherited identifiers.
			RefByUUID = Catalogs.Companies.GetRef(
				New UUID(XDTOOrganization.objectID.ID));
			
			// An RLS exception is possible.
			Query = New Query(
				"SELECT ALLOWED TOP 1
				|	Companies.Ref AS Ref
				|FROM
				|	Catalog.Companies AS Companies
				|WHERE
				|	Companies.Ref = &RefByUUID");
			Query.SetParameter("RefByUUID", RefByUUID);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				// The company has been found.
				Result = Selection.Ref;
				
			ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTOOrganization, "name")
					And XDTOOrganization.name <> "" Then
				
				// We will continue the search by INN/CHECKPOINT.
				Description = XDTOOrganization.name;
				TIN = "";
				CRTR = "";
				
				If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOOrganization, "inn") Then
					TIN = XDTOOrganization.inn;
				EndIf;
				If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOOrganization, "kpp") Then
					CRTR = XDTOOrganization.kpp;
				EndIf;
				
				Query = New Query(
					"SELECT ALLOWED
					|	Companies.Ref AS Ref,
					|	0 AS Priority
					|FROM
					|	Catalog.Companies AS Companies
					|WHERE
					|	&TIN <> """"
					|	AND &CRTR <> """"
					|	AND Companies.TIN = &TIN
					|	AND Companies.CRTR = &CRTR
					|	AND NOT Companies.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Companies.Ref,
					|	1
					|FROM
					|	Catalog.Companies AS Companies
					|WHERE
					|	&TIN <> """"
					|	AND (&CRTR = """"
					|			OR Companies.CRTR = """")
					|	AND Companies.TIN = &TIN
					|	AND Companies.Description = &Description
					|	AND NOT Companies.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Companies.Ref,
					|	2
					|FROM
					|	Catalog.Companies AS Companies
					|WHERE
					|	&CRTR <> """"
					|	AND (&TIN = """"
					|			OR Companies.TIN = """")
					|	AND Companies.CRTR = &CRTR
					|	AND Companies.Description = &Description
					|	AND NOT Companies.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Companies.Ref,
					|	3
					|FROM
					|	Catalog.Companies AS Companies
					|WHERE
					|	&TIN <> """"
					|	AND (&CRTR = """"
					|			OR Companies.CRTR = """")
					|	AND Companies.TIN = &TIN
					|	AND NOT Companies.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Companies.Ref,
					|	4
					|FROM
					|	Catalog.Companies AS Companies
					|WHERE
					|	(&TIN = """"
					|			OR Companies.TIN = """")
					|	AND (&CRTR = """"
					|			OR Companies.CRTR = """")
					|	AND Companies.Description = &Description
					|	AND NOT Companies.DeletionMark
					|
					|ORDER BY
					|	Priority");
				Query.SetParameter("TIN", TIN);
				Query.SetParameter("CRTR", CRTR);
				Query.SetParameter("Description", Description);
				
				Selection = Query.Execute().Select();
				If Selection.Next() Then
					
					// The company has been found.
					Result = Selection.Ref;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If TypeOf(ValueToFillIn) = Type("XDTODataObject")
			And IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ValueToFillIn, "DMBankAccount")
			And IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "number") Then
		Query = New Query;
		RequestTextArray = New Array;
		If ObjectAttributeTypeIS = Type("CatalogRef.CounterpartyBankAccounts") Then
			RequestTextArray.Add(
				"SELECT
				|	BankAccounts.Ref AS Ref
				|FROM
				|	Catalog.CounterpartyBankAccounts AS BankAccounts
				|WHERE
				|	BankAccounts.AccountNumber = &AccountNumber
				|	AND NOT BankAccounts.DeletionMark");
		ElsIf ObjectAttributeTypeIS = Type("CatalogRef.CompaniesBankAccounts") Then
			RequestTextArray.Add(
				"SELECT
				|	BankAccounts.Ref AS Ref
				|FROM
				|	Catalog.CompaniesBankAccounts AS BankAccounts
				|WHERE
				|	BankAccounts.AccountNumber = &AccountNumber
				|	AND NOT BankAccounts.DeletionMark");
		Else
			Return;
		EndIf;
		Query.SetParameter("AccountNumber", ValueToFillIn.number);
		
		Bank = Undefined;
		If IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "bank") Then
			Bank = IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
				Type("CatalogRef.BankClassifier"),
				IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(
					ValueToFillIn.bank));
		EndIf;
		If ValueIsFilled(Bank) Then
			RequestTextArray.Add("AND BankAccounts.Bank = &Bank");
			Query.SetParameter("Bank", Bank);
		EndIf;
		
		Owner = Undefined;
		If IntegrationWith1CDocumentManagementCore.PropertySet(ValueToFillIn, "owner") Then
			OwnerType = IntegrationWith1CDocumentManagementCoreServerCall.TypeIS(
				ValueToFillIn.owner.objectID.type);
			If ValueIsFilled(OwnerType) Then
				Owner = IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
					OwnerType,
					IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(
						ValueToFillIn.owner));
			EndIf;
		EndIf;
		If ValueIsFilled(Owner) Then
			RequestTextArray.Add("AND BankAccounts.Owner = &Owner");
			Query.SetParameter("Owner", Owner);
		EndIf;
		
		Query.Text = StrConcat(RequestTextArray, Chars.LF);
		
		Selection = Query.Execute().Select();
		If Selection.Count() = 1 Then
			Selection.Next();
			Result = Selection.Ref;
		EndIf;
	EndIf;
	
	// Change the State of the document.
	PropertyNameBefore = "";
	ObjectTypeXDTO = "";
	PropertyValue = ValueToFillIn;
	If TypeOf(ValueToFillIn) = Type("Structure") Then
		PropertyNameBefore = ValueToFillIn.PropertyName;
		ObjectTypeXDTO = ValueToFillIn.ObjectTypeXDTO;
		PropertyValue = ValueToFillIn.PropertyValue;
	EndIf;
	
	StateOfApprovalBefore = Undefined;
	ApprovalStateDM = Undefined;
	
	If IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(Proxy, ValueToFillIn)
			And ValueToFillIn.objectID.type = "DMDocumentStatus" Then
		
		If ValueToFillIn.objectID.ID = "Согласован" Then //@NON-NLS-1
			StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved;
		ElsIf ValueToFillIn.objectID.ID = "НеСогласован" Then //@NON-NLS-1
			StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved;
		ElsIf ValueToFillIn.objectID.ID = "НаСогласовании" Then //@NON-NLS-1
			StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval;
			
		ElsIf ValueToFillIn.objectID.ID = "Утвержден" Then //@NON-NLS-1
			ApprovalStateDM = "Confirmed";
		ElsIf ValueToFillIn.objectID.ID = "НеУтвержден" Then //@NON-NLS-1
			ApprovalStateDM = "NotConfirmed";
		ElsIf ValueToFillIn.objectID.ID = "НаУтверждении" Then //@NON-NLS-1
			ApprovalStateDM = "AwaitingConfirmation";
		EndIf;
		
	ElsIf TypeOf(ValueToFillIn) = Type("Structure")
			And ValueToFillIn.ObjectTypeXDTO = "DMDocument"
			And StrFind(ValueToFillIn.PropertyName, "status") = 1 Then
		
		If PropertyValue = "Approved" Then
			StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved;
		ElsIf PropertyValue = "NotApproved" Then
			StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved;
		ElsIf PropertyValue = "AwaitingApproval" Then
			StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval;
			
		ElsIf PropertyValue = "Confirmed"
				Or PropertyValue = "NotConfirmed"
				Or PropertyValue = "AwaitingConfirmation" Then
			ApprovalStateDM = PropertyValue;
		EndIf;
		
	EndIf;
	
	StateOfERPApproval = IntegrationWith1CDocumentManagementERP.StateOfERPApproval(
		ObjectAttributeTypeIS,
		AttributeNameObjectIS,
		TypeOfIPObjectToFillIn,
		StateOfApprovalBefore);
	StateOfApprovalOfERP = IntegrationWith1CDocumentManagementERP.StateOfApprovalOfERP(
		ObjectAttributeTypeIS,
		AttributeNameObjectIS,
		TypeOfIPObjectToFillIn,
		ApprovalStateDM);
	
	StateOfApplicationUH = "";
	
	IncorrectDataWasTransmitted = False;
	If ValueIsFilled(StateOfERPApproval) Then
		
		// The EPP Attributes known to us are filled in.
		Result = StateOfERPApproval;
		If StateOfApprovalBefore = Undefined And PropertyValue <> Undefined Then
			// The default Attribute value has been selected from the previously unknown data.
			IncorrectDataWasTransmitted = True;
		Else
			If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
				StateOfApplicationUH = "AwaitingConfirmation";
			ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
				StateOfApplicationUH = "IsRejected";
			ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
				StateOfApplicationUH = "Approved";
			EndIf;
		EndIf;
		
	ElsIf ValueIsFilled(StateOfApprovalOfERP) Then
		
		// The EPP Attributes known to us are filled in.
		Result = StateOfApprovalOfERP;
		If ApprovalStateDM = Undefined And PropertyValue <> Undefined Then
			// The default Attribute value has been selected from the previously unknown data.
			IncorrectDataWasTransmitted = True;
		Else
			If ApprovalStateDM = "AwaitingConfirmation" Then
				StateOfApplicationUH = "AwaitingConfirmation";
			ElsIf ApprovalStateDM = "NotConfirmed" Then
				StateOfApplicationUH = "IsRejected";
			ElsIf ApprovalStateDM = "Confirmed" Then
				StateOfApplicationUH = "Approved";
			EndIf;
		EndIf;
		
	EndIf;
	
	
	If IncorrectDataWasTransmitted Then
		IntegrationWith1CDocumentManagementCore.FixErrorInSelectingAttributeValue(
			Proxy,
			PropertyValue,
			ObjectAttributeTypeIS,
			ObjectToFillInIS,
			AttributeNameObjectIS,
			PropertyNameBefore,
			ObjectTypeXDTO);
	EndIf;
	
EndProcedure

// Allows you to redefine the index of the image of the directory element.
//
// Parameters:
//   ImageSize - Number - index of the image.
//
Procedure WhenDeterminingIndexOfImageOfCatalogItem(ImageSize) Export
	
	
	
EndProcedure

// Allows you to override the check for the need to output the command of attached files from
// the integration library with 1C:Document flow to the form of the IP object.
//
// Parameters:
//   Form - ClientApplicationForm - the form being checked.
//   ItIsNecessaryToOutputCommand - Boolean - an implicit return value, the result of verification. If the result is True,
//     the "Files TO" Command will be displayed on the Form.
//
// Example:
//	Formname Array = Split Page(Form.Formname, ".");
//	Type name of the Form objectform = Template("%1.%2", Array formname[0], Array formName[1]);
//	Rules = integration1sdocumentoviewerserver calls.Appropriate Rule(,, Type name of the Form object);
//	
//	If The Rules.Quantity() = 0 Then
//		It is possible that the module being redefined contains automatic creation of rules for this type of IP object
//		Created Rules = integration1sdocumentoviewerserver calls.Create Integration rules automatically(
//			Type name of the Form object);
//		If the created rule.Quantity() > 0 Then
//			Rules = integration1sdocumentoviewerserver calls.Appropriate Rule(,,Type name of the Form object);
//		The end if;
//	The end if;
//	
//	You need to issue a command = (Rules.Quantity() <> 0);
//
Procedure OnDetermineTheNeedToOutputTheAttachedFilesCommandDM(Form, ItIsNecessaryToOutputCommand) Export
	
	FormNameArray = StrSplit(Form.FormName, ".");
	ObjectName = StrTemplate("%1.%2", FormNameArray[0], FormNameArray[1]);
	
	If Form.FormName = "Catalog.CounterpartyContracts.Form.ItemForm"
			Or Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		Ref = IntegrationWith1CDocumentManagementCore.ReferenceToIntegratedObjectFromForm(Form);
		
		Try
			// Let's define the possibility of storing files in UP to.
			FormType = FormNameArray[FormNameArray.UBound()];
			If FormType = "ItemForm" Or FormType = "DocumentForm" Then
				ItIsNecessaryToOutputCommand = IntegrationWith1CDocumentManagementCoreServerCall.IntegrationConfiguredForObject(Ref);
			Else
				Rules = IntegrationWith1CDocumentManagementCoreServerCall.FindCreateAppropriateRules(
					Undefined,
					ObjectName,
					False);
				ItIsNecessaryToOutputCommand = (Rules.Count() <> 0);
			EndIf;
		Except
			ItIsNecessaryToOutputCommand = False;
		EndTry;
		
		If ItIsNecessaryToOutputCommand And Form.FormName = "Catalog.CounterpartyContracts.Form.ItemForm" Then
			If Form.UseIntegrationBefore2 Then
				// When using UP TO 2 BSP file pages, you need to hide them only if it is empty.
				Form.Items.FilesPage.Visible =
					IntegrationWith1CDocumentManagementCoreServerCall.ThereAreStoredVISFiles(Ref);
			ElsIf Form.UseIntegrationBefore3 Then
				// The Form of attached files UP to 3 can transfer files from the ERP to the DO.
				// The BSP file page needs to be hidden.
				Form.Items.FilesPage.Visible = False;
			EndIf;
		EndIf;
		
		Return;
		
	EndIf;
	
	If Form.Items.Find("CommonCommandAttachedFiles") <> Undefined
			Or Form.Items.Find("GeneralCommandIsToAttachFilesToObject") <> Undefined
			Or Form.Items.Find("GeneralCommandAttachedBZKFiles") <> Undefined
			Or Form.Items.Find("ListCommonCommandAttachedFiles") <> Undefined
			Or Form.Items.Find("FormOfGeneralCommandAttachedFiles") <> Undefined
			Or Form.Items.Find("FormGeneralCommandAttachedFilesToObject") <> Undefined
			Or Form.Items.Find("FormGeneralCommandAttachedBPCFiles") <> Undefined
			Or Form.FormName = "Document.CommercialProposalForCustomer.Form.ListForm"
			Or Form.FormName = "Document.SupplierSCommercialOffer.Form.ListForm" Then
		ItIsNecessaryToOutputCommand = False;
	EndIf;
	
EndProcedure

// Defines the details of the conducted document to be updated when they are changed in the TO.
//
// Parameters:
//   FullName - String - the full name of the object as it is specified in the metadata, e.g. Document.Customer's order.
//   UpdatedBankingDetails - Array of String - an implicitly returned value, the names of the details that can be updated.
//
// Example:
//	Updatedrequisits.Add ("Comment");
//	If Fullname = "Document.Customer's order" Then
//		Updatedrequisits.Add("State");
//	The end if;
//
Procedure WhenDeterminingUpdatedDetailsOfConductedDocument(FullName, UpdatedBankingDetails) Export
	
	UpdatedBankingDetails.Add("Comment");
	UpdatedBankingDetails.Add("Status");
	UpdatedBankingDetails.Add("Approved");
	
EndProcedure

// Called when building a list of integrable objects. In the transmitted table, you should add
// object types that support automatic configuration of seamless integration with the creation
// of integration rules and filling in related data.
//
// Parameters:
//   Objects - ValueTable - a table with columns to be filled in:
//     The object type name is a string - the full name of the type, as specified in the metadata.
//     The description of the actions to be performed is a string - optional, a brief description of the actions performed
//        during automatic configuration.
//
// Example:
//	String = Objects.Add();
//	Line.Object Type Name = "Catalog._demodescontragents";
//	Line.Description of the actions to be performed =
//		NStr("ru = 'Integration rules and types of internal documents for all types of Contracts will be created.'");
//
Procedure WhenDefiningObjectsThatSupportAutoTuning(Objects) Export
	
	String = Objects.Add();
	String.ObjectTypeName = "Catalog.TermsOfSale";
	String.DescriptionOfActionsPerformed =
		NStr("vi = 'Sẽ tạo quy tắc tích hợp và dạng văn bản nội bộ đối với danh mục ""Thỏa thuận về các điều kiện bán hàng"".';
			|ru = 'Будут созданы правила интеграции и вид внутренних документов для справочника ""Соглашения об условиях продаж"".';
			|en = 'Integration rules and a kind of internal transfer documents for the ""Terms of sale"" catalog will be created.'; fa = 'Integration rules and a kind of internal transfer documents for the ""Terms of sale"" catalog will be created.';
			|it = 'Saranno create regole di integrazione e il tipo di documenti interni per la directory ""Accordo sulle condizioni di vendita"".';
			|pl = 'Zostaną utworzone reguły integracji i rodzaj dokumentów zewnętrznych dla katalogu ""Umowy o warunkach sprzedaży"".';
			|tr = '""Satış şart ve hükümleri"" kataloğu için entegrasyon kuralları ve dahili belge türü oluşturulacaktır.'");
	
	String = Objects.Add();
	String.ObjectTypeName = "Catalog.CounterpartyContracts";
	String.DescriptionOfActionsPerformed =
		NStr("vi = 'Sẽ tạo quy tắc tích hợp và dạng văn bản nội bộ đối với danh mục ""Hợp đồng với đối tác"".';
			|ru = 'Будут созданы правила интеграции и вид внутренних документов для справочника ""Договоры с контрагентами"".';
			|en = 'Integration rules and a kind of internal transfer documents for the ""Contracts"" catalog will be created.'; fa = 'Integration rules and a kind of internal transfer documents for the ""Contracts"" catalog will be created.';
			|it = 'Saranno create regole di integrazione e il tipo di documenti interni per la directory ""Accordi con le controparti"".';
			|pl = 'Zostaną utworzone reguły integracji i rodzaj dokumentów wewnętrznych dla katalogu ""Umowy z kontrahentami"".';
			|tr = '""Cari hesap sözleşmeleri"" kataloğu için entegrasyon kuralları ve dahili belge türü oluşturulacaktır.'");
	
	String = Objects.Add();
	String.ObjectTypeName = "Document.CommercialProposalForCustomer";
	String.DescriptionOfActionsPerformed =
		NStr("vi = 'Sẽ tạo quy tắc tích hợp và dạng văn bản nội bộ đối với danh mục ""Báo giá cho khách hàng"".';
			|ru = 'Будут созданы правила интеграции и вид внутренних документов для документа ""Коммерческое предложение клиенту"".';
			|en = 'Integration rules and a kind of internal transfer documents for the ""Sales quotation"" catalog will be created.'; fa = 'Integration rules and a kind of internal transfer documents for the ""Sales quotation"" catalog will be created.';
			|it = 'Saranno create regole di integrazione e il tipo di documenti interni per il documento ""Proposta commerciale al cliente"".';
			|pl = 'Zostaną utworzone reguły integracji i rodzaj dokumentów wewnętrznych dla dokumentów ""Oferty cenowe klientowi"".';
			|tr = '""Satış teklifi"" belgesi için entegrasyon kuralları ve  dahili belge türü oluşturulacaktır.'");
	
	String = Objects.Add();
	String.ObjectTypeName = "Document.SalesOrder";
	String.DescriptionOfActionsPerformed =
		NStr("vi = 'Sẽ tạo quy tắc tích hợp và dạng văn bản nội bộ đối với chứng từ ""Đơn hàng của khách"".';
			|ru = 'Будут созданы правила интеграции и вид внутренних документов для документа ""Заказ клиента"".';
			|en = 'Integration rules and a kind of internal transfer documents for the ""Sales order"" document will be created.'; fa = 'Integration rules and a kind of internal transfer documents for the ""Sales order"" document will be created.';
			|it = 'Saranno create regole di integrazione e il tipo di documenti interni per il documento ""Ordine cliente"".';
			|pl = 'Zostaną utworzone reguły integracji i rodzaj dokumentów wewnętrznych dla dokumentu ""Zamówienie klienta"".';
			|tr = '""Satış siparişi"" belgesi için entegrasyon kuralları ve dahili belge türü oluşturulacaktır.'");
	
	String = Objects.Add();
	String.ObjectTypeName = "Document.PurchaseOrder";
	String.DescriptionOfActionsPerformed =
		NStr("vi = 'Sẽ tạo quy tắc tích hợp và dạng văn bản nội bộ đối với chứng từ ""Đơn hàng đặt nhà cung cấp"".';
			|ru = 'Будут созданы правила интеграции и вид внутренних документов для документа ""Заказ поставщику"".';
			|en = 'Integration rules and a kind of internal transfer documents for the ""Purchase order"" document will be created.'; fa = 'Integration rules and a kind of internal transfer documents for the ""Purchase order"" document will be created.';
			|it = 'Saranno create regole di integrazione e il tipo di documenti interni per il documento ""Ordine fornitore"".';
			|pl = 'Zostaną utworzone reguły integracji i rodzaj dokumentów wewnętrznych dla dokumentu ""Zamówienie do dostawcy"".';
			|tr = '""Satın alma siparişi"" belgesi için entegrasyon kuralları ve dahili belge türü oluşturulacaktır.'");
	
	String = Objects.Add();
	String.ObjectTypeName = "Document.RequestForReturnOfGoodsFromCustomer";
	String.DescriptionOfActionsPerformed =
		NStr("vi = 'Sẽ tạo quy tắc tích hợp và dạng văn bản nội bộ đối với chứng từ ""Giấy đề nghị trả hàng từ người mua"".';
			|ru = 'Будут созданы правила интеграции и вид внутренних документов для документа ""Заявка на возврат товаров от клиента"".';
			|en = 'Integration rules and a kind of internal transfer documents for the ""Sales return request"" document will be created.'; fa = 'Integration rules and a kind of internal transfer documents for the ""Sales return request"" document will be created.';
			|it = 'Saranno create regole di integrazione e il tipo di documenti interni per il documento ""Richiesta di reso articoli da cliente"".';
			|pl = 'Zostaną utworzone reguły integracji i rodzaj dokumentów wewnętrznych dla dokumentu ""Wniosek o zwrot towarów od klienta"".';
			|tr = '""Müşteriden mal iadesi talebi"" belgesi için entegrasyon kuralları ve dahili belge türü oluşturulacaktır.'");
	
	String = Objects.Add();
	String.ObjectTypeName = "Document.PaymentRequest";
	String.DescriptionOfActionsPerformed =
		NStr("vi = 'Sẽ tạo quy tắc tích hợp và dạng văn bản nội bộ đối với chứng từ ""Giấy đề nghị thanh toán"".';
			|ru = 'Будут созданы правила интеграции и вид внутренних документов для документа ""Заявка на расходование денежных средств"".';
			|en = 'Integration rules and a kind of internal transfer documents for the ""Payment demand"" document will be created.'; fa = 'Integration rules and a kind of internal transfer documents for the ""Payment demand"" document will be created.';
			|it = 'Saranno create regole di integrazione e tipi di documenti interni per il documento ""Richiesta di spesa dei fondi"".';
			|pl = 'Zostaną utworzone reguły integracji i rodzaj dokumentów wewnętrznych dla dokumentu ""Wniosek o wydatkowanie środków pieniężnych"".';
			|tr = '""Ödeme talebi"" belgesi için entegrasyon kuralları ve dahili belge türü oluşturulacaktır.'");
	
EndProcedure

// Called when adding a link to the IP object associated with the DO object.
// Allows you to supplement the list of suitable objects presented to the user with those objects that
// cannot be identified automatically by links from the header or from the tabular parts of the IP object.
//
// Parameters:
//   ObjectIS - AnyRef - reference to the IP object.
//   SuitableObjects - Array of AnyRef - an augmented array of IP objects suitable for adding communication.
//     Used when unloading an IC object in UP to 2.
//                     - See IntegrationWith1CDocumentManagement3.SuitableObjectsForAddingLinks
//
Procedure WhenDeterminingSuitableObjectsToAddLink(ObjectIS, SuitableObjects) Export
	
	
	
EndProcedure

// Allows you to override the receipt of an explanation of the approval status intended for reading by the user.
//
// Parameters:
//   Set - String - a representation of the user who has set the new state.
//   InstallationDate - Date - date and time when the new state was set.
//   Explanation - String - explanation of the approval status.
//
Procedure WhenDeterminingCurrentStateOfApproval(Set, InstallationDate, Explanation) Export
	
	
	
EndProcedure

// Allows you to redefine the maximum number of objects selected by the service when receiving lists.
//
// Parameters:
//   Type - String - object type XDTO
//   MaximumQuantity - Number - the maximum number of elements selected at a time.
//
// Example:
//	If Type = "DMCorrespondent" Then the maximum quantity = 50 and if <...>
//
Procedure WhenDeterminingMaximumNumberOfSelectedObjects(Type, MaximumQuantity) Export
	
	
	
EndProcedure

// Allows you to redefine the maximum number of objects that will be uploaded to the
// exchange message with 1C:Document flow.
//
// Parameters:
//   MaximumNumberOfObjectsInMessage - Number - the maximum number of objects.
//
// Example:
//	Maximum number of objectsthe message = 100;
//
Procedure WhenDeterminingMaximumNumberOfObjectsInExchangeMessage(MaximumNumberOfObjectsInMessage) Export
	
	
	
EndProcedure

// Overrides the view view of the integrated configuration object.
//
// Parameters:
//   Rule - CatalogObject.RulesForIntegrationWith1CDocumentManagement
//           - CatalogObject.RulesForIntegrationWith1CDocumentManagement3 - the rule for which
//     the view is defined.
//   PresentationOfConsumerObjectView - String - an implicitly returned value, an overridden representation
//             of the object view. By default, it is defined as a representation of an object with key details.
//
// Example:
//	If the Rule.Type of objectis = "Document.The receipt of the " Then
//		Structurepoisk = New Structure;
//		Structure of the search.Insert ("Key", True);
//		Structure of the search.Insert("Name of the requesitaobject", "Type of operation");
//		Key Session results = The rule.Rules for filling out requesitovis.Find strings(Search structurereferences);
//		If the key session is.Quantity() > 0 Then
//			Type of Operation = Key Session[0].Valuerequisitais;
//			If the type of operation = Enumeration.Types of operationsapplication of product services.The Goods Then
//				Representation of the Consumer's ViewObject = NStr("ru = 'Goods (waybill)'");
//			The end if;
//		The end if;
//	The end if;
//
Procedure WhenDefiningPresentationViewOfConsumerObject(Rule, PresentationOfConsumerObjectView) Export
	
	
	
EndProcedure

// Overrides the representation of the integrated configuration object. It is used if the standard
// representation of a synonym and key details separated by commas turns out to be insufficiently readable.
//
// Parameters:
//   Rule - CatalogObject.RulesForIntegrationWith1CDocumentManagement
//           - CatalogObject.RulesForIntegrationWith1CDocumentManagement3 - the rule for which
//     the view is defined.
//   ConsumerObjectPresentation - String - an implicitly returned value, an overridden representation
//             of an object. By default, it is collected from the synonym of the object and the values of the key details of the rule.
//
// Example:
//	If the Rule.Type of objectis = "Document.The receipt of the " Then
//		Structurepoisk = New Structure;
//		Structure of the search.Insert("Key", True);
//		Structure of the search.Insert("Name of the requesitaobject", "Type of operation");
//		Key Session results = The rule.Rules for filling out requesitovis.Find strings(Search structurereferences);
//		If the key session is.Quantity() > 0 Then
//			Type of Operation = Key Session[0].Valuerequisitais;
//			If the type of operation = Enumeration.Types of operationsapplication of product services.The Goods Then
//				Consumer Objectobject Representation = NStr("ru = 'Receipt of goods'");
//			Or if the type of operation = Enumeration.Types of operationsapplication of product services.Services Then
//				Consumer Objectobject Representation = NStr("ru = 'Receipt of services'");
//			The end if;
//		The end if;
//	The end if;
//
Procedure WhenDefiningPresentationOfConsumerObject(Rule, ConsumerObjectPresentation) Export
	
	
	
EndProcedure

// Allows you to override getting integration availability for the current user. It can be redefined
// if you refuse to use the supplied role using Integration and Document management.
//
// Parameters:
//   Allowed1 - Boolean - True if the use of integration is allowed.
//
Procedure WhenDeterminingUserPermissionToUseIntegration(Allowed1) Export
	
	
	
EndProcedure

// Allows you to redefine getting the ability to start a negotiation in UP to.
//
// Parameters:
//   SubjectOfApproval - AnyRef - the agreed object is.
//   WarningText - String - implicitly returned value, warning text.
//   Allowed1 - Boolean - True, if the start of the agreement is allowed, False - prohibited, Undefined - according to the roles.
//
// Example:
//	If the type of VHF(Subject of agreement) = Type("Document Link.Buyer's _democorder") Then
//		If the subject of the agreement.The State <> of the Enumeration._The state of the buyer's order.Upon Agreement Then
//			Text of the warning = NStr("ru = 'Creation of the approval process is allowed only on the basis of
//				|documents in State ""On approval"".'");
//			Allowed = A lie;
//		The end if;
//	The end if;
//
Procedure WhenDeterminingUserSPermissionToStartNegotiation(SubjectOfApproval, WarningText,
		Allowed1) Export
	
	
	
EndProcedure

// Allows you to redefine getting the possibility of interrupting the negotiation in UP to.
//
// Parameters:
//   SubjectOfApproval - AnyRef - the agreed object is.
//   SubjectOfBefore - Structure - description of the linked object BEFORE:
//      the name string is a Presentation of the linked object.
//      ID String is the ID of the linked object.
//      type - String is the name of the XDTO type.
//   WarningText - String - implicitly returned value, warning text.
//   Allowed1- Boolean - True, if the termination of the agreement is allowed, False - prohibited, Undefined - according to the roles.
//
Procedure WhenDeterminingUserSPermissionToInterruptNegotiation(SubjectOfApproval, SubjectOfBefore,
		WarningText, Allowed1) Export
	
	
	
EndProcedure

// Specifies the abbreviated name of the integrated configuration for output in headers and decorations.
//
// Parameters:
//   NameAbbreviated - String - implicitly returned value, short name of the configuration.
//
// Example:
//	Abbreviated Name = NStr("ru = '1C:ERP ERP'");
//
Procedure WhenDefiningAbbreviatedConfigurationName(NameAbbreviated) Export
	
	If GetFunctionalOption("ComplexAutomation") Then
		NameAbbreviated = NStr("vi = '1C:CA';
								|ru = '1С:КА';
								|en = '1C:PA'; fa = '1C:PA';
								|it = '1C:CA';
								|pl = '1C:PA';
								|tr = '1C:CA'");
		
	ElsIf GetFunctionalOption("TradeManagement") Then
		NameAbbreviated = NStr("vi = '1C:TM';
								|ru = '1С:УТ';
								|en = '1C:TM'; fa = '1C:TM';
								|it = '1C:TM';
								|pl = '1С:SM';
								|tr = '1C:TM'");
		
	ElsIf Common.SubsystemExists("ПодсистемыУХ") Then
		NameAbbreviated = NStr("vi = '1С:ERP.УХ';
								|ru = '1С:ERP.УХ';
								|en = '1C:ERP.CPM'; fa = '1C:ERP.CPM';
								|it = '1С:ERP.УХ';
								|pl = '1C:ERP.CPM';
								|tr = '1C:ERP. CPM'");
		
	Else
		NameAbbreviated = NStr("vi = '1C:ERP';
								|ru = '1С:ERP УП';
								|en = '1C:ERP EM'; fa = '1C:ERP EM';
								|it = '1C:ERP EM';
								|pl = '1С:ERP EM';
								|tr = '1C:ERP EM  '");
		
	EndIf;
	
EndProcedure

// Called when determining the timeout of the web service. If necessary, the timeout can be taken to the
// integration administrator settings and redefined in this procedure.
//
// Parameters:
//   Timeout - Number - an implicitly returned value, the time in seconds after which the call
//     to the Workflow web service is considered unsuccessful.
//
Procedure WhenDeterminingServiceTimeout(Timeout) Export
	
	
	
EndProcedure

// Redefines the types of IP objects that support seamless integration. By default, it is filled with all
// the types that are part of the parameter types of the common commands of the integration subsystem with the document flow.
//
// Parameters:
//   Types - Array of Type - array of objects of Type Type.
//
Procedure WhenDefiningObjectTypesThatSupportIntegration(Types) Export
	
	If Not GetFunctionalOption("UseCustomerRebates") Then
		CommonClientServer.DeleteValueFromArray(Types, Type("CatalogRef.CustomerRebatesKinds"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.AccrualOfCustomerRebates"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.DebitCustomerRebates"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.ConditionsOfCustomerRebates"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.CustomerBonusCertificate"));
	EndIf;
	
	If Not GetFunctionalOption("UseVendorRebates") Then
		CommonClientServer.DeleteValueFromArray(Types, Type("CatalogRef.VendorRebateKinds"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.AccrualOfVendorRebates"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.WriteOffVendorRebates"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.ConditionsOfVendorRebates"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.VendorBonusCertificate"));
	EndIf;
	
	If Not GoodsDeliveryClientServer.UsedDelivery25() Then
		
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.DeliveryOrder"));
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.Trip"));
		
	EndIf;
	If Not GetFunctionalOption("UseAlternativeMaterials") Then
		CommonClientServer.DeleteValueFromArray(Types, Type("DocumentRef.EngineeringChangeOrder"));
	EndIf;
EndProcedure

// Allows you to override the receipt of the barcode of the document to assign the associated document TO.
//
// Parameters:
//   Document - AnyRef - the IP object on the basis of which the document is created BEFORE.
//   Barcode - String - barcode to assign to the linked document BEFORE.
//
// Example:
//	If you get a functional option ("Use three-encoding of printed formobjects") Then
//		Hexadecimal = NReg(Replace(Document.Unique Identifier(), "-", ""));
//		String Length = Length(Hexadecimal);
//		Result = 0;
//		For the character number = 1 By the length Of the string, the loop
//			Result = Result * 16 + Find("0123456789abcdef",
//				Means(Hexadecimal, Character number, 1)) - 1;
//		The end of the cycle;
//		Barcode = Format(Result, "HG=0");
//	Otherwise
//		Barcode = "";
//	The end if;
//
Procedure WhenDeterminingBarcodeOfDocument(Document, Barcode) Export
	
	If GetFunctionalOption("UseBarcodingOfObjectPrintForms") Then
		HexadecimalNumber = Lower(StrReplace(Document.UUID(), "-", ""));
		StringLength = StrLen(HexadecimalNumber);
		Result = 0;
		For CharacterNumber = 1 To StringLength Do
			Result = Result * 16 + Find("0123456789abcdef",
				Mid(HexadecimalNumber, CharacterNumber, 1)) - 1;
		EndDo;
		Barcode = Format(Result, "NG=0");
	Else
		Barcode = "";
	EndIf;
	
EndProcedure

// Called when the WSPROXY is received. It is overridden if the configuration has the ability to configure an Internet proxy.
//
// Parameters:
//   InternetProxy - Undefined - an implicitly returned value can be initialized
//     with an Internetproxy type value.
//
Procedure WhenReceivingWSProxy(InternetProxy) Export
	
	InternetProxy = GetFilesFromInternet.GetProxy("http");
	
EndProcedure

// Called when filling in the object Attributes table by object type.
//
// Parameters:
//   ObjectNameIS - String - the full name of the consumer object type.
//   Attributes - ValueTable - The table of the description of the details.
//
Procedure WhenReceivingAttributesOfIPObject(ObjectNameIS, Attributes) Export
	
	
	
EndProcedure

// Allows you to redefine or supplement the list of constants that depend on each other. It is necessary when, when
// one constant is turned on, any other constants should be turned off and vice versa.
//
// Parameters:
//   TableOfConstants - See IntegrationWith1CDocumentManagementCore.DependenciesOfConstants
//
// Example:
//	Integrations1documentobase functionality.Add a line to the table with a dependencyconstant(
//		tableconstant,
//		"Use the agreement through1 Document flow",
//		True,
//		"Use the internal agreement to return customer goods",
//		False);
//
Procedure WhenRetrievingConstantDependencyTable(TableOfConstants) Export
	
	// Approval via 1C:Document flow
	IntegrationWith1CDocumentManagementCore.AddRowToConstantDependencyTable(
		TableOfConstants,
		"UseApprovalThrough1CDocumentManagement",
		True,
		Metadata.Constants.UseInternalApprovalOfRequestsForReturnOfGoodsFromCustomers.Name,
		False);
	IntegrationWith1CDocumentManagementCore.AddRowToConstantDependencyTable(
		TableOfConstants,
		"UseApprovalThrough1CDocumentManagement",
		True,
		Metadata.Constants.UseInternalSalesOrderApproval.Name,
		False);
	IntegrationWith1CDocumentManagementCore.AddRowToConstantDependencyTable(
		TableOfConstants,
		"UseApprovalThrough1CDocumentManagement",
		True,
		Metadata.Constants.UseInternalApprovalOfTermsOfSales.Name,
		False);
	IntegrationWith1CDocumentManagementCore.AddRowToConstantDependencyTable(
		TableOfConstants,
		"UseApprovalThrough1CDocumentManagement",
		True,
		Metadata.Constants.UseInternalCoordinationOfCommercialProposals.Name,
		False);
	
	IntegrationWith1CDocumentManagementCore.AddRowToConstantDependencyTable(
		TableOfConstants,
		"UseApprovalThrough1CDocumentManagement",
		False,
		Metadata.Constants.UseInternalApprovalOfRequestsForReturnOfGoodsFromCustomers.Name,
		Constants.UseApprovalOfRequestsForReturnOfGoodsFromCustomers.Get());
	IntegrationWith1CDocumentManagementCore.AddRowToConstantDependencyTable(
		TableOfConstants,
		"UseApprovalThrough1CDocumentManagement",
		False,
		Metadata.Constants.UseInternalSalesOrderApproval.Name,
		Constants.UseSalesOrderApproval.Get());
	IntegrationWith1CDocumentManagementCore.AddRowToConstantDependencyTable(
		TableOfConstants,
		"UseApprovalThrough1CDocumentManagement",
		True,
		Metadata.Constants.UseInternalApprovalOfTermsOfSales.Name,
		Constants.UseApprovalOfTermsOfSales.Get());
	
EndProcedure

// Allows you to override the receipt of a JWT token for authentication in the Workflow web service.
//
// Parameters:
//   TextOfAccessToken - String - an implicit return value, a JWT token with a string.
//
// Example:
//	Access tokens = New Access Token;
//	Token ParameterStoken = Integration1sdocumentobase functionality.Access Access parameterof();
//	Fill in the Property values (Access token, Token parameters);
//	Token signingkey = Constants.The key for signing the Access key1sdocument flow.Get();
//	Access tokens.Sign(Access key signing algorithm.HS256, Token signing key);
//	Access Control Text = String(Access token);
//
Procedure WhenReceivingAccessToken(TextOfAccessToken) Export
	
	
	
EndProcedure

// Allows you to override the check whether the integrated system can create electronic signatures
// for 1C objects:Document management.
// Required if an overridable integration settings Form and a constant are used
// To create an instance for objects1, the document turnover of the means is not displayed in the user interface.
//
// Parameters:
//   Result - Boolean - an implicitly returned value, the result of the check.
//   StandardProcessing - Boolean - an implicitly returned value, indicating that the standard check
//     does not need to be performed.
//
Procedure WhenCheckingAbilityToCreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem(Result,
		StandardProcessing) Export
	
	
	
EndProcedure

// Checks the compliance of the integration rule with functional options. It is called when a suitable rule
// is selected and allows you to discard rules related to objects that are disabled by the FO.
//
// Parameters:
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the rule being checked.
//   ObjectTypeDM - String - the object type is UP TO.
//   ObjectTypeIS - String - IP object type (full name in metadata).
//   Cancel - Boolean - when set to True, the rule will not be used.
//   KeyAttributeName - String - the name of the key props of the rule.
//   ValueOfKeyProps - Arbitrary - the value of the key props of the rule.
//
// Example:
//	If the type of the objectis = "Document.Receipt of the loan"
//			And Do not get a functional option ("Account is kept") Then
//		Rejection = Truth;
//		Refund;
//	The end if;
//
Procedure WhenCheckingWhetherRuleMatchesFunctionalOptions(Rule, ObjectTypeDM, ObjectTypeIS, Cancel,
		KeyAttributeName = "", ValueOfKeyProps = Undefined) Export
	
	ArrayOfTypesOfRebatesForCustomers = New Array; // Array of String
	ArrayOfTypesOfRebatesForCustomers.Add("Catalog.CustomerRebatesKinds");
	ArrayOfTypesOfRebatesForCustomers.Add("Document.ConditionsOfCustomerRebates");
	ArrayOfTypesOfRebatesForCustomers.Add("Document.AccrualOfCustomerRebates");
	ArrayOfTypesOfRebatesForCustomers.Add("Document.DebitCustomerRebates");
	ArrayOfTypesOfRebatesForCustomers.Add("Document.CustomerBonusCertificate");
	
	If ArrayOfTypesOfRebatesForCustomers.Find(ObjectTypeIS) <> Undefined
			And Not GetFunctionalOption("UseCustomerRebates") Then
		Cancel = True;
	EndIf;
	
	ArrayOfTypesOfRebateVendorBasedWebmaps = New Array; // Array of String
	ArrayOfTypesOfRebateVendorBasedWebmaps.Add("Catalog.VendorRebateKinds");
	ArrayOfTypesOfRebateVendorBasedWebmaps.Add("Document.ConditionsOfVendorRebates");
	ArrayOfTypesOfRebateVendorBasedWebmaps.Add("Document.AccrualOfVendorRebates");
	ArrayOfTypesOfRebateVendorBasedWebmaps.Add("Document.WriteOffVendorRebates");
	ArrayOfTypesOfRebateVendorBasedWebmaps.Add("Document.VendorBonusCertificate");
	
	If ArrayOfTypesOfRebateVendorBasedWebmaps.Find(ObjectTypeIS) <> Undefined
			And Not GetFunctionalOption("UseVendorRebates") Then
		Cancel = True;
	EndIf;
	
	TypesOfDelivery25 = New Array; // Array of String
	TypesOfDelivery25.Add("Document.DeliveryOrder");
	TypesOfDelivery25.Add("Document.Trip");
	
	If TypesOfDelivery25.Find(ObjectTypeIS) <> Undefined
			And Not GoodsDeliveryClientServer.UsedDelivery25() Then
		Cancel = True;
	EndIf;
	ArrayOfDocumentTypes_ = New Array; // Array of String
	ArrayOfDocumentTypes_.Add("Document.EngineeringChangeOrder");
	
	If ArrayOfDocumentTypes_.Find(ObjectTypeIS) <> Undefined
			And Not GetFunctionalOption("UseAlternativeMaterials") Then
		Cancel = True;
	EndIf;
EndProcedure

// Overrides the representation of the integration rule selection form. It is used when the rules are ambiguous and
// allows you to offer the user a less technogenic form of choice.
//
// Parameters:
//   Form - ClientApplicationForm - The selection form has been processed by integration1sdocumentation.
//
// Example:
//	The form.Title = NStr("ru = 'Document form'");
//	The form.Autoloading = A lie;
//	The form.Explanation = NStr("ru = 'Select the document type:'");
//	The form.Elements.Explanation.Visibility = Truth;
//
Procedure WhenCreatingRuleSelectionFormOnServer(Form) Export
	
	
	
EndProcedure

// Called when creating an IP object by reference in the Attributes of the BEFORE object. It can be used to
// top up the Attributes of a new IP object, for example, if the standard filling handler
// does not fill in the required Attributes by default.
// Attention, since this procedure can be performed during data exchange with the DO, it
// is not recommended to perform any calls to the DO web service, as well as to receive a proxy of the DO service.
//
// Parameters:
//   ObjectIS - Arbitrary - an IC object created but not yet recorded.
//   XDTODataObject - XDTODataObject - the original object whose match was not found in the current IB.
//   ObjectToFillInIS - Arbitrary - the IP object, during the filling of which the creation is called
//     ObjectIS by reference. Provides the context needed to populate the ObjectIS.
//
// Example:
//	If the type of map item(object) = Type("Reference object._demoorganizations") Then
//		ObjectIS.Legal entity = Transfers.Legal entity.Legal entity;
//		If ObjectXDTO.ObjectId.type = "DMOrganization"
//				And ObjectXDTO.ObjectId.ID = "Individual Entrepreneur" Then
//			ObjectIS.Legal entity = Transfers.Legal entity.Individual Entrepreneur;
//		The end if;
//	The end if;
//	If the type of map item(object) = Type("Reference object._demobankaccount")
//			And ObjectXDTO.ObjectId.type = "DMBankAccount" Then
//		ObjectIS.Account number = ObjectXDTO.number;
//	The end if;
//
Procedure WhenCreatingLink(ObjectIS, XDTODataObject, ObjectToFillInIS = Undefined) Export
	
	If TypeOf(ObjectIS) = Type("CatalogObject.Companies")
			Or TypeOf(ObjectIS) = Type("CatalogObject.Counterparties") Then
		
		SourceXDTO = Undefined;
		If (XDTODataObject.objectID.type = "DMParty" Or XDTODataObject.Type().Name = "DMParty") Then
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "correspondent") Then
				SourceXDTO = XDTODataObject.correspondent;
			ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "organization") Then
				SourceXDTO = XDTODataObject.organization;
			EndIf;
			
		ElsIf XDTODataObject.objectID.type = "DMCorrespondent" Or XDTODataObject.objectID.type = "DMOrganization" Then
			SourceXDTO = XDTODataObject;
			
		EndIf;
		
		If SourceXDTO <> Undefined Then
			ObjectIS.TIN = SourceXDTO.inn;
			ObjectIS.CRTR = SourceXDTO.kpp;
			ObjectIS.NCBOCode = SourceXDTO.okpo;
			ObjectIS.DescriptionFull = SourceXDTO.fullName;
		EndIf;
		
		If Not ValueIsFilled(ObjectIS.DescriptionFull) Then
			ObjectIS.DescriptionFull = XDTODataObject.name;
		EndIf;
		
		ObjectIS.LegalEntityIndividual = IntegrationWith1CDocumentManagementERP.LegalEntityNaturalPersonFromXDTOObject(SourceXDTO);
		
	EndIf;
	
	If TypeOf(ObjectIS) = Type("CatalogObject.Counterparties") And Not ValueIsFilled(ObjectIS.Partner) Then
		GUID = ObjectIS.GetNewObjectRef().UUID();
		RelatedPartner = Catalogs.Partners.GetRef(GUID);
		DataFromDocumentBeingFilledIn = New Structure("Partner");
		FillPropertyValues(DataFromDocumentBeingFilledIn, ObjectToFillInIS);
		If Common.RefExists(RelatedPartner) Then
			ObjectIS.Partner = RelatedPartner;
		ElsIf ValueIsFilled(DataFromDocumentBeingFilledIn.Partner) Then
			ObjectIS.Partner = DataFromDocumentBeingFilledIn.Partner;
		Else
			Query = New Query(
				"SELECT
				|	Partners.Ref AS Partner
				|FROM
				|	Catalog.Partners AS Partners
				|WHERE
				|	Partners.Description = &Description
				|	AND NOT Partners.DeletionMark");
			Query.SetParameter("Description", ObjectIS.Description);
			Selection = Query.Execute().Select();
			If Selection.Count() = 1 Then
				Selection.Next();
				ObjectIS.Partner = Selection.Partner;
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(ObjectIS) = Type("CatalogObject.Partners") Then
		
		SourceXDTO = Undefined;
		If (XDTODataObject.objectID.type = "DMParty" Or XDTODataObject.Type().Name = "DMParty") Then
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "correspondent") Then
				SourceXDTO = XDTODataObject.correspondent;
			ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "organization") Then
				SourceXDTO = XDTODataObject.organization;
			EndIf;
			
		ElsIf XDTODataObject.objectID.type = "DMCorrespondent" Or XDTODataObject.objectID.type = "DMOrganization" Then
			SourceXDTO = XDTODataObject;
			
		EndIf;
		
		If SourceXDTO <> Undefined And ValueIsFilled(SourceXDTO.fullName) Then
			ObjectIS.DescriptionFull = SourceXDTO.fullName;
		Else
			ObjectIS.DescriptionFull = XDTODataObject.name;
		EndIf;
		
		LegalEntityNaturalPersonFromXDTOObject = IntegrationWith1CDocumentManagementERP.LegalEntityNaturalPersonFromXDTOObject(SourceXDTO);
		If LegalEntityNaturalPersonFromXDTOObject = Enums.LegalEntityIndividual.Entity
				Or LegalEntityNaturalPersonFromXDTOObject = Enums.LegalEntityIndividual.LegalEntityNonResident Then
			ObjectIS.LegalEntityIndividual = Enums.IndividualCompany.Company;
		Else
			ObjectIS.LegalEntityIndividual = Enums.IndividualCompany.Person_;
		EndIf;
		
		If Not ValueIsFilled(ObjectIS.AccessGroup) Then
			ObjectIS.AccessGroup = IntegrationWith1CDocumentManagementERP.PartnerAccessGroupByDefault();
		EndIf;
		
		If Not ObjectIS.Client And Not ObjectIS.Vendor And Not ObjectIS.OtherRelations And Not ObjectIS.Competitor
				And Not ObjectIS.ServedBySalesRepresentatives And Not ObjectIS.Carrier Then
			// The type of relationship with the partner is unknown.
			ObjectIS.Client = True;
			ObjectIS.Vendor = True;
		EndIf;
		
		BeginTransaction();
		Try
			LinkOfNewPartner = ObjectIS.GetNewObjectRef();
			GUID = LinkOfNewPartner.UUID();
			RelatedCounterparty = Catalogs.Counterparties.GetRef(GUID);
			If Common.RefExists(RelatedCounterparty) Then
				CounterpartySPartner = Common.ObjectAttributeValue(RelatedCounterparty, "Partner");
				If Not ValueIsFilled(CounterpartySPartner) Then
					Counterparty = RelatedCounterparty.GetObject();
					Counterparty.Lock();
					Counterparty.Partner = LinkOfNewPartner;
					Counterparty.Write();
				EndIf;
			EndIf;
			DataFromDocumentBeingFilledIn = New Structure("Counterparty");
			FillPropertyValues(DataFromDocumentBeingFilledIn, ObjectToFillInIS);
			If ValueIsFilled(DataFromDocumentBeingFilledIn.Counterparty) Then
				CounterpartySPartner = Common.ObjectAttributeValue(
					DataFromDocumentBeingFilledIn.Counterparty, "Partner");
				If Not ValueIsFilled(CounterpartySPartner) Then
					Counterparty = DataFromDocumentBeingFilledIn.Counterparty.GetObject();
					Counterparty.Lock();
					Counterparty.Partner = LinkOfNewPartner;
					Counterparty.Write();
				EndIf;
			EndIf;
			Query = New Query(
				"SELECT ALLOWED
				|	Counterparties.Ref AS Ref
				|FROM
				|	Catalog.Counterparties AS Counterparties
				|WHERE
				|	Counterparties.Description = &Description
				|	AND NOT Counterparties.DeletionMark
				|	AND Counterparties.Partner = VALUE(Catalog.Partners.EmptyRef)");
			Query.SetParameter("Description", ObjectIS.Description);
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				Counterparty = Selection.Ref.GetObject();
				Counterparty.Lock();
				Counterparty.Partner = LinkOfNewPartner;
				Counterparty.Write();
			EndDo;
			CommitTransaction();
		Except
			RollbackTransaction();
			IntegrationWith1CDocumentManagementCore.WriteWarning(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
	
	If XDTODataObject.objectID.type = "DMPrivatePerson" And TypeOf(ObjectIS) = Type("CatalogObject.Persons") Then
		ObjectIS.LastFirstName = XDTODataObject.name;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "birthDay") Then
			ObjectIS.BirthDate = XDTODataObject.birthDay;
		EndIf;
		
	EndIf;
	
	If XDTODataObject.objectID.type = "DMSubdivision"
			And TypeOf(ObjectIS) = Type("CatalogObject.BusinessStructure")
			And IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "head") Then
		
		ObjectIS.BusinessUnitManager = IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
			Type("CatalogRef.Persons"),
			IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(
				XDTODataObject.head));
		
	EndIf;
	
	If XDTODataObject.objectID.type = "DMBankAccount"
			And (TypeOf(ObjectIS) = Type("CatalogObject.CounterpartyBankAccounts")
				Or TypeOf(ObjectIS) = Type("CatalogObject.CompaniesBankAccounts")) Then
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "bank") Then
			ObjectIS.Bank = IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
				Type("CatalogRef.BankClassifier"),
				IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(
					XDTODataObject.bank));
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "number") Then
			ObjectIS.AccountNumber = XDTODataObject.number;
		EndIf;
		
	EndIf;
	
	If XDTODataObject.objectID.type = "DMVATRateUniversal" And TypeOf(ObjectIS) = Type("CatalogObject.VATRates") Then
		
		ObjectIS.BeginOfPeriod = XDTODataObject.beginOfPeriod;
		ObjectIS.EndOfPeriod = XDTODataObject.endOfPeriod;
		ObjectIS.Rate1 = XDTODataObject.rate;
		ObjectIS.CalculatedRate = XDTODataObject.calculatedRate;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "country") Then
			ObjectIS.Country = IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
				Type("CatalogRef.WorldCountries"),
				IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(
					XDTODataObject.country));
		EndIf;
		NewRow = ObjectIS.VATTaxationTypes.Add();
		NewRow.VATTaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
		
	EndIf;
	
EndProcedure

// Allows you to override the default filling rule setting when uploading.
//
// Parameters:
//   FillingRules - Map of KeyAndValue - matching Attribute names to XDTO properties:
//     * Key - String - name of the prop.
//     * Value - String - the name of the XDTO property.
//   Receiver - String - the name of the XDTO-type of the receiver.
//   Source - String - the full name of the source metadata object.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//
Procedure WhenSettingDefaultUploadFillRule(FillingRules, Receiver, Source,
		StandardProcessing) Export
	
	
	
EndProcedure

// Allows you to override the default setting of the fill rule when loading.
//
// Parameters:
//   FillingRules - Map of KeyAndValue - matching Attribute names to XDTO properties:
//     * Key - String - name of the prop.
//     * Value - See IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO
//   Receiver - String - the full name of the receiver metadata object.
//   Source - String - the name of the source's XDTO type.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//
Procedure WhenSettingTheDefaultFillInRuleOnLoading(FillingRules, Receiver, Source,
		StandardProcessing) Export
	
	
	
EndProcedure

// It is called when updating the BID, and checks the correctness of the composition of the defined types with the exchange plan.
//
// Parameters:
//   Errors - Array of String - a list of errors detected during the check.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that
//     the standard check will not be performed.
//
Procedure VerifyComplianceOfDefinedTypesAndExchangePlan(Errors, StandardProcessing) Export
	
	
	
EndProcedure

// It is called when updating the BID, and checks the correctness of the composition of the defined types among themselves.
//
// Parameters:
//   Errors - Array of String - a list of errors detected during the check.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that
//     the standard check will not be performed.
//
Procedure CheckCorrespondenceOfDefinedTypesWithEachOther(Errors, StandardProcessing) Export
	
	
	
EndProcedure

// Sets the modes of changing the props available for selection in the conducted document.
//
// Parameters:
//   ObjectTypeIS - String - representation of the object type of the integrated system.
//   AttributeIS - String - presentation of the integrated system's props.
//   ChoiceList - ValueList of EnumRef.ModeOfChangingPostedDocumentBy1CDocumentManagementData -
//     available values of the modes of changing props.
//
// Example:
//	If the type of the objectis = "Document.Customer's Order" And Details = "Status" Then
//		List of selections.Clear();
//		List of selections.Add(
//			Transfers.The mode of change of the performed yeardocuments1documentation.Allowed by the survey);
//		List of selections.Add(
//			Transfers.The mode of change of the performed yeardocuments1documentation.Forbidden);
//	The end if;
//
Procedure SetModesOfChangeInConductedDocument(ObjectTypeIS, AttributeIS, ChoiceList) Export
	
	If ObjectTypeIS = "Document.SalesOrder" And AttributeIS = "Status" Then
		ChoiceList.Clear();
		ChoiceList.Add(
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting);
		ChoiceList.Add(
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited);
	EndIf;
	
EndProcedure

#EndRegion