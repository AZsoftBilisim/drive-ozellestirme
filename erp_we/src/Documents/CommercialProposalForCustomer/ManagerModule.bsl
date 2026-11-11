#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	AccountingSettings = CommercialProposalsDocuments.AccountingSettings();
	
	If AccountingSettings.DoNotDisplayDiscountsInSalesDocuments Then
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager                 = "Document.CommercialProposalForCustomer";
		PrintCommand.Id                  = "CommercialProposalForCustomer";
		PrintCommand.Presentation                  = NStr("vi = 'Báo giá cho khách hàng';
															|ru = 'Коммерческое предложение клиенту';
															|en = 'Sales quotation'; fa = 'پیش‌فاکتور فروش';
															|it = 'Offerta commerciale al cliente';
															|pl = 'Oferta cenowa do klienta';
															|tr = 'Satış teklifi'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Picture = PictureLib.Print;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters = AdditionalParameters;
	
	ElsIf AccountingSettings.SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments Then
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager                 = "Document.CommercialProposalForCustomer";
		PrintCommand.Id                  = "CommercialProposalForCustomer";
		PrintCommand.Presentation                  = NStr("vi = 'Báo giá cho khách hàng (có giảm giá)';
															|ru = 'Коммерческое предложение клиенту (со скидками)';
															|en = 'Sales quotation (with discounts)'; fa = 'Sales quotation (with discounts)';
															|it = 'Offerta commerciale al cliente (con sconti)';
															|pl = 'Oferta handlowa klientowi (z rabatami)';
															|tr = 'Satış teklifi (indirimli)'");
		PrintCommand.CheckPostingBeforePrint = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters = AdditionalParameters;
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager                 = "Document.CommercialProposalForCustomer";
		PrintCommand.Id                  = "CommercialProposalForCustomer";
		PrintCommand.Presentation                  = NStr("vi = 'Báo giá cho khách hàng (không giảm giá)';
															|ru = 'Коммерческое предложение клиенту (без скидок)';
															|en = 'Sales quotation (without discount)'; fa = 'Sales quotation (without discount)';
															|it = 'Offerta commerciale al cliente (senza sconti)';
															|pl = 'Oferta handlowa klientowi (bez rabatów)';
															|tr = 'Satış teklifi (indirimsiz)'");
		PrintCommand.CheckPostingBeforePrint = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters = AdditionalParameters;
		
	Else
		
		// Commercial proposal
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "Document.CommercialProposalForCustomer";
		PrintCommand.Id = "CommercialProposalForCustomer";
		PrintCommand.Presentation = NStr("vi = 'Báo giá cho khách hàng';
										|ru = 'Коммерческое предложение клиенту';
										|en = 'Sales quotation'; fa = 'پیش‌فاکتور فروش';
										|it = 'Offerta commerciale al cliente';
										|pl = 'Oferta cenowa do klienta';
										|tr = 'Satış teklifi'");
		PrintCommand.CheckPostingBeforePrint = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters = AdditionalParameters;
		PrintCommand.Picture = PictureLib.Print;
		
	EndIf;
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to the objects that you want to print.
//  PrintParameters - Structure - additional print settings.
//  PrintFormsCollection - ValueTable - generated tabular documents.
//  PrintObjects         - ValueList  - value-reference to the view object - name of the output area.
//  OutputParameters       - Structure       - additional parameters of generated table documents.
//
Procedure Print(Val ObjectsArray, Val PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CommercialProposalForCustomer") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
			"CommercialProposalForCustomer",
			NStr("vi = 'Báo giá cho khách hàng';
				|ru = 'Коммерческое предложение клиенту';
				|en = 'Sales quotation'; fa = 'پیش‌فاکتور فروش';
				|it = 'Offerta commerciale al cliente';
				|pl = 'Oferta cenowa do klienta';
				|tr = 'Satış teklifi'"),
			PrintedFormCommercialOfferToClient(ObjectsArray, PrintObjects, PrintParameters));
		
	EndIf;
	
EndProcedure 

#EndRegion

#Region ReportsCommands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - ValueTable - A table with report commands. For changes.
//       See the description of parameter 1 of the report variationreferences procedure.Before adding Team reports().
//   Parameters - Structure - Auxiliary parameters. For reading.
//       See the description of the 2 parameters of the procedure variationreportable.Before adding Team reports().
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	CommercialProposalsDocumentsOverridable.OnAddReportsCommands("Document.CommercialProposalForCustomer", 
	                                                                            ReportsCommands,
	                                                                            Parameters);
	
EndProcedure

#EndRegion

#Region IntegrationOfMessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
	 CommercialProposalsDocumentsOverridable.OnPrepareMessageTemplate(Attributes,
	                                                                                Attachments, 
	                                                                                AdditionalParameters);
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
	CommercialProposalsDocumentsOverridable.OnCreateMessage(Message,
	                                                                          MessageSubject,
	                                                                          AdditionalParameters);
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
	CommercialProposalsDocumentsOverridable.OnFillRecipientsPhonesInMessage(SMSMessageRecipients,
	                                                                                             MessageSubject);
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - options for sending a message "To", "Copy", "hidden Copy", "return Address".
//   MessageSubject - AnyRef - a reference to the object that is the data source.
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
	CommercialProposalsDocumentsOverridable.OnFillRecipientsEmailsInMessage(EmailRecipients,
	                                                                                         MessageSubject);
	
EndProcedure

#EndRegion

#Region ToDoList

// See ToDoListOverridable.OnDetermineToDoListHandlers.
//
Procedure OnFillToDoList(ToDoList) Export
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled = AccessRight("Edit", Metadata.Documents.CommercialProposalForCustomer)
		And AccessRight("Read", Metadata.InformationRegisters.StatesOfCommercialProposalsToCustomers);
	
	If Not Enabled Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenFillingInListOfCurOfBusinessCommercialOffers(ToDoList, "CommercialProposalForCustomer");
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal


#Region InterfaceImplementation


// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Documents.CommercialProposalForCustomer, True);
	Lists.Insert(Metadata.Catalogs.CommercialProposalForCustomerAttachedFiles, True);
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	CommercialProposalsDocumentsOverridable.OnFillMetadataObjectsAccessRestrictionKinds(
		"Document.CommercialProposalForCustomer", LongDesc);
	CommercialProposalsDocumentsOverridable.OnFillMetadataObjectsAccessRestrictionKinds(
		"Catalog.CommercialProposalForCustomerAttachedFiles", LongDesc);
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
Procedure OnFillAccessRestriction(Restriction) Export
	
	CommercialProposalsDocumentsOverridable.OnFillAccessRestriction(
		"Document.CommercialProposalForCustomer", Restriction);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region GenerationCommands

Function AddGenerateCommand(GenerationCommands) Export
	
	Result = Undefined;
	CommercialProposalsDocumentsOverridable.InitializingFormCommands("AddGenerateCommand",
		Metadata.Documents.CommercialProposalForCustomer.Name, GenerationCommands, Result);
	Return Result;
	
EndFunction

Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	CommercialProposalsDocumentsOverridable.InitializingFormCommands("AddGenerationCommands",
		Metadata.Documents.CommercialProposalForCustomer.Name, GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

Function PrintedFormCommercialOfferToClient(ObjectsArray, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	DataForPrint = DataForPrint(ObjectsArray, PrintParameters);
	
	HeaderData_   = DataForPrint.HeaderResults.Select();  // QueryResultSelection
	GoodsTable = DataForPrint.ResultsByProducts.Unload(); // ValueTable
	
	TableOfDocumentProducts_ = New ValueTable;
	For Each ValueTableColumn In GoodsTable.Columns Do
		TableOfDocumentProducts_.Columns.Add(ValueTableColumn.Name, ValueTableColumn.ValueType);
	EndDo;
	
	FirstDocument = True;
	
	While HeaderData_.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TableOfDocumentProducts_.Clear();
		
		SearchParameters = New Structure;
		SearchParameters.Insert("Ref", HeaderData_.Ref);
		
		FoundRows = GoodsTable.FindRows(SearchParameters);
		
		For Each FoundRow In FoundRows Do
			NewRow = TableOfDocumentProducts_.Add();
			FillPropertyValues(NewRow, FoundRow);
		EndDo;
		
		ObjectData = ObjectDataByPrintData(HeaderData_, TableOfDocumentProducts_);
		FillInTabularDocumentCommercialOfferToClient(SpreadsheetDocument, ObjectData, PrintParameters);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, HeaderData_.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Fill out the tabular document commercial offer to the client.
// 
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - 
//  ObjectData     - Structure -
//  PrintParameters   - Structure - 
//
Procedure FillInTabularDocumentCommercialOfferToClient(SpreadsheetDocument, ObjectData, PrintParameters)
	
	Template = PrintManagement.PrintFormTemplate("Document.CommercialProposalForCustomer.PF_MXL_CommercialProposalForCustomer");
	
	If PrintParameters.Property("DisplayDiscounts_")
		And Not PrintParameters.DisplayDiscounts_ Then
		
		If ObjectData.OptionToSpecifyDeliveryTerm = Enums.DeliveryPeriodOptionsForCommercialProposals.NotisSpecified Then
			AreaNameTableHeader             = "ProductsTableHeader";
			AreaNameTableRow            = "RowOfProductsTable";
			NameOfNamedAreaTableRow = "ScopeOfApplication_10";
		Else
			AreaNameTableHeader             = "TableHeaderProductsDeliveryTime";
			AreaNameTableRow            = "TableRowProductsDeliveryTime";
			NameOfNamedAreaTableRow = "ScopeOfDeliveryDeliveryTime";
		EndIf;
		
	Else
		
		If ObjectData.OptionToSpecifyDeliveryTerm = Enums.DeliveryPeriodOptionsForCommercialProposals.NotisSpecified Then
			AreaNameTableHeader             = "HeaderTableProductsDiscount";
			AreaNameTableRow            = "TableRowProductsDiscount";
			NameOfNamedAreaTableRow = "AreaProductsDiscount";
		Else
			AreaNameTableHeader             = "TableHeaderProductsDeliveryTimeDiscount";
			AreaNameTableRow            = "TableRowProductsDeliveryTimeDiscount";
			NameOfNamedAreaTableRow = "ScopeOfGoodsDeliveryTimeDiscount";
		EndIf;
		
	EndIf;
	
	BarcodeArea_                = Template.GetArea("BarcodeArea_");
	HeaderArea_                = Template.GetArea("Title");
	AreaContactPerson           = Template.GetArea("ContactPerson");
	WeOfferYouToGetAcquainted   = Template.GetArea("WeOfferToGetAcquainted");
	ProductsTableHeaderArea       = Template.GetArea(AreaNameTableHeader);
	AreaRowOfProductsTable      = Template.GetArea(AreaNameTableRow);
	NamedAreaStringProducts  = NameOfNamedAreaTableRow;
	AreaBasementTableGoods      = Template.GetArea("BasementTableGoods");
	AreaManager                 = Template.GetArea("Manager");
	EmptyStringAreaIsThin       = Template.GetArea("EmptyStringIsThin");
	AreaAdditionalInformation = Template.GetArea("AdditionalInformation");
	ScopePeriodOfValidity_             = Template.GetArea("ValidityPeriodPartialRedemption");
	
	CommercialProposalsDocumentsOverridable.WhenDisplayingBarCodeInPrintedForms(SpreadsheetDocument, Template, BarcodeArea_, ObjectData);
	
	CommercialProposalsDocumentsOverridable.WhenFormingTitleOfPrintedForm(Template, HeaderArea_, ObjectData);
	
	AdditionalOutputParameters = Undefined;
	
	HeaderArea_.Parameters.Fill(ObjectData);
	SpreadsheetDocument.Put(HeaderArea_);
	
	If ValueIsFilled(ObjectData.ContactPerson) Then
		AreaContactPerson.Parameters.Fill(ObjectData);
		SpreadsheetDocument.Put(AreaContactPerson);
	EndIf;
	
	WeOfferYouToGetAcquainted.Parameters.Fill(ObjectData);
	SpreadsheetDocument.Put(WeOfferYouToGetAcquainted);
	
	SpreadsheetDocument.Put(ProductsTableHeaderArea);
	
	For Each LineProducts_ In ObjectData.Goods Do
		
		StandardProcessing = True;
		CommercialProposalsDocumentsOverridable.WhenDisplayingLineInPrintedForm(SpreadsheetDocument,
		                                                                                    LineProducts_,
		                                                                                    AreaRowOfProductsTable,
		                                                                                    NamedAreaStringProducts,
		                                                                                    AdditionalOutputParameters,
		                                                                                    StandardProcessing);
		
		If StandardProcessing Then
			AreaRowOfProductsTable.Parameters.Fill(LineProducts_);
			SpreadsheetDocument.Put(AreaRowOfProductsTable);
		EndIf;
		
	EndDo;
	
	AreaBasementTableGoods.Parameters.Fill(ObjectData);
	SpreadsheetDocument.Put(AreaBasementTableGoods);
	
	SpreadsheetDocument.Put(EmptyStringAreaIsThin);
	
	ScopePeriodOfValidity_.Parameters.Fill(ObjectData);
	SpreadsheetDocument.Put(ScopePeriodOfValidity_);
	
	If Not IsBlankString(ObjectData.TermsOfDeliveryPresentation) Then
		
		SpreadsheetDocument.Put(EmptyStringAreaIsThin);
		AreaAdditionalInformation.Parameters.Fill(ObjectData);
		SpreadsheetDocument.Put(AreaAdditionalInformation);
		
	EndIf;
	
	AreaManager.Parameters.Fill(ObjectData);
	SpreadsheetDocument.Put(AreaManager);
	
EndProcedure

// Preparing object data from data for printing.
// 
// Parameters:
// 	HeaderData_ - QueryResultSelection
// 	GoodsTable - ValueTable - Goods:
//    * LineNumber - Number
Function ObjectDataByPrintData(HeaderData_, GoodsTable)

	ObjectData = New Structure;
	
#Region ThisOrganization
	
	OrganizationInformation__ = New Structure;
	OrganizationInformation__.Insert("Description");
	OrganizationInformation__.Insert("FullDescr");
	OrganizationInformation__.Insert("Phones");
	OrganizationInformation__.Insert("LegalAddress");
	OrganizationInformation__.Insert("Email");
	
	CommercialProposalsDocumentsOverridable.FillInOrganizationData(HeaderData_.Organization, OrganizationInformation__);
	
	If ValueIsFilled(OrganizationInformation__.FullDescr) Then
		RepresentationOfTheOrganization = OrganizationInformation__.FullDescr;
	Else
		RepresentationOfTheOrganization = OrganizationInformation__.Description;
	EndIf;
	
#EndRegion
	
#Region ContactInformation
	
	If ValueIsFilled(HeaderData_.Manager) Then
		
		WorkingWithManager = New Array;
		WorkingWithManager.Add(HeaderData_.Manager);
		
		RequiredTypesOfContactInformation = New Array;
		RequiredTypesOfContactInformation.Add(Enums.ContactInformationTypes.Email);
		
		ContactInformationTable1 = ContactsManager.ObjectsContactInformation(
		                                   WorkingWithManager,
		                                   RequiredTypesOfContactInformation,,
		                                   HeaderData_.Date);
		
		ManagerSEmailAddress = CommercialProposalsDocuments.PresentationOfContactInformationFromTable(
		                                   ContactInformationTable1,
		                                   Enums.ContactInformationTypes.Email);
		
	Else
		ManagerSPhoneNumber = "";
		ManagerSEmailAddress   = "";
	EndIf;
	
#EndRegion

#Region Goods

	ThereAreDiscounts = False;
	ObjectData.Insert("AmountTotal", 0);
	ObjectData.Insert("AmountTotalVAT", 0);
	ObjectData.Insert("GoodsQuantity", 0);
	ObjectData.Insert("Goods", New Array);
	
	For Each LineProducts_ In GoodsTable Do
		
		If LineProducts_.DiscountAmount <> 0 Then
			ThereAreDiscounts = True;
		EndIf;
		
		ObjectData.AmountTotal        = ObjectData.AmountTotal + LineProducts_.Sum;
		ObjectData.AmountTotalVAT     = ObjectData.AmountTotalVAT + LineProducts_.VATAmount;
		ObjectData.GoodsQuantity = ObjectData.GoodsQuantity + 1;
		
		RowOfProductsTable = New Structure;
		
		ProductName = CommercialProposalsDocumentsClientServer.PresentationOfProductsForPrinting(LineProducts_.Products, LineProducts_.Characteristic);
		
		RowOfProductsTable.Insert("LineNumber",      LineProducts_.LineNumber);
		RowOfProductsTable.Insert("Products",     ProductName);
		RowOfProductsTable.Insert("Count",       LineProducts_.Count);
		RowOfProductsTable.Insert("UnitOfMeasure", LineProducts_.UnitOfMeasure);
		RowOfProductsTable.Insert("Price",             Format(LineProducts_.Price,"NFD=2; NDS=."));
		RowOfProductsTable.Insert("AmountIncludingVAT",        Format(LineProducts_.AmountIncludingVAT,"NFD=2; NDS=."));
		RowOfProductsTable.Insert("DiscountAmount",      Format(LineProducts_.DiscountAmount,"NFD=2; NDS=."));
		RowOfProductsTable.Insert("DeliveryPeriodDays",     CommercialProposalsDocumentsClientServer.DeliveryTimeByLine(HeaderData_.OptionToSpecifyDeliveryTerm, 
		                                                                                                                  LineProducts_.DeliveryPeriodDays));
		
		CommercialProposalsDocumentsOverridable.AddObjectDataForPrinting(RowOfProductsTable, LineProducts_, ObjectData);
		
		ObjectData.Goods.Add(RowOfProductsTable);
		
	EndDo;

#EndRegion

#Region FillingInObjectData 

	PresentationOfDocumentAmounts = CommercialProposalsDocuments.PresentationOfDocumentAmountsForPrinting(HeaderData_,
	                                                                                                  ObjectData.AmountTotal,
	                                                                                                  ObjectData.AmountTotalVAT,
	                                                                                                  ObjectData.GoodsQuantity);
	
	ObjectData.Insert("Ref",                              HeaderData_.Ref);
	ObjectData.Insert("Organization",                         HeaderData_.Organization);
	ObjectData.Insert("CompanyPhone",                  OrganizationInformation__.Phones);
	ObjectData.Insert("OrganizationAddress",                    OrganizationInformation__.LegalAddress);
	ObjectData.Insert("OrganizationSEmailAddress",    ?(OrganizationInformation__.Property("Email"),OrganizationInformation__.Email, ""));
	ObjectData.Insert("Client",                              HeaderData_.Client);
	ObjectData.Insert("Counterparty",                          HeaderData_.Counterparty);
	ObjectData.Insert("RepresentationOfTheOrganization",            RepresentationOfTheOrganization);
	ObjectData.Insert("CustomerPresentation_",                CustomerPresentation_(ObjectData.Client, ObjectData.Counterparty));
	ObjectData.Insert("ContactPerson",                      HeaderData_.ContactPerson);
	ObjectData.Insert("Manager",                            HeaderData_.Manager);
	ObjectData.Insert("ManagerSEmailAddress",      ManagerSEmailAddress);
	ObjectData.Insert("ManagerSPhoneNumber",                    ManagerSPhoneNumber);
	ObjectData.Insert("Number",                               ObjectsPrefixesClientServer.NumberForPrinting(HeaderData_.Number, False, True));
	ObjectData.Insert("Date",                                Format(HeaderData_.Date,"DLF=D"));
	ObjectData.Insert("OptionToSpecifyDeliveryTerm",        HeaderData_.OptionToSpecifyDeliveryTerm);
	ObjectData.Insert("PaymentTerm",                       HeaderData_.PaymentTerm);
	ObjectData.Insert("DeliveryTerms",                     HeaderData_.DeliveryTerms);
	ObjectData.Insert("OtherConditions",                       HeaderData_.OtherConditions);
	ObjectData.Insert("OfferContactInformation",     OfferContactInformation(ObjectData));
	ObjectData.Insert("TotalString",                      PresentationOfDocumentAmounts.TotalString);
	ObjectData.Insert("AmountInWords",                       PresentationOfDocumentAmounts.AmountInWords);
	ObjectData.Insert("ThereAreDiscounts",                          ThereAreDiscounts);
	ObjectData.Insert("PresentationOfValidityPeriod",          CommercialProposalsDocuments.PresentationOfExpirationDateForPrinting(ThereAreDiscounts, HeaderData_.ValidityPeriod));
	ObjectData.Insert("PresentationOfPartialRedemption",       CommercialProposalsDocuments.PresentationOfPartialRedemptionForPrinting(HeaderData_.PartialSaleAllowed));
	ObjectData.Insert("TermsOfDeliveryPresentation",        CommercialProposalsDocuments.PresentationOfDeliveryTermsForPrinting(ObjectData.PaymentTerm, 
	                                                                                                                                     ObjectData.DeliveryTerms, 
	                                                                                                                                     ObjectData.OtherConditions));
	
#EndRegion
	
	Return ObjectData;
	
EndFunction

Function CustomerPresentation_(Client, Counterparty)
	
	Return CommercialProposalsDocuments.PresentationOfCounterpartySPartner(Client, Counterparty);
	
EndFunction

Function OfferContactInformation(ObjectData)
	
	RowsArray = New Array;
	
	If Not IsBlankString(ObjectData.OrganizationAddress) Then
		RowsArray.Add(ObjectData.OrganizationAddress);
	EndIf;
	
	If Not IsBlankString(ObjectData.CompanyPhone) Then
		RowsArray.Add(ObjectData.CompanyPhone);
	EndIf;
	
	If Not IsBlankString(ObjectData.ManagerSEmailAddress) Then
		RowsArray.Add(ObjectData.ManagerSEmailAddress);
	ElsIf Not IsBlankString(ObjectData.OrganizationSEmailAddress) Then
		RowsArray.Add(ObjectData.OrganizationSEmailAddress);
	EndIf;
	
	Return StrConcat(RowsArray, Chars.LF);
	
EndFunction

// Data for printing objects.
// 
// Parameters:
// 	ObjectsArray  - Array    - print objects.
// 	PrintParameters - Structure - Parameters:
// 	  * DisplayDiscounts_ - Boolean - to enable discounts.
// Returns:
// 	Structure - LongDesc:
//    * HeaderResults   - QueryResultSelection
//    * ResultsByProducts - QueryResultSelection
Function DataForPrint(ObjectsArray, PrintParameters)
	
	DataStructureForPrinting = Undefined;
	StandardProcessing = True;
	CommercialProposalsDocumentsOverridable.CommercialOfferToClientWhenFormingPrintDataStructure(
		ObjectsArray,
		DataStructureForPrinting,
		PrintParameters,
		StandardProcessing);
		
	If Not StandardProcessing Then
		Return DataStructureForPrinting;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	DisplayDiscounts_ = True;
	If PrintParameters.Property("DisplayDiscounts_")
		And Not PrintParameters.DisplayDiscounts_ Then
		DisplayDiscounts_ = False;
	EndIf;
	
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	
	Query.Text =
	"SELECT
	|	CommercialProposalForCustomer.Ref                              AS Ref,
	|	CommercialProposalForCustomer.Date                                AS Date,
	|	CommercialProposalForCustomer.Number                               AS Number,
	|	CommercialProposalForCustomer.Manager                            AS Manager,
	|	CommercialProposalForCustomer.ContactPerson                      AS ContactPerson,
	|	CommercialProposalForCustomer.Organization                         AS Organization,
	|	CommercialProposalForCustomer.ValidityPeriod                        AS ValidityPeriod,
	|	CommercialProposalForCustomer.Currency                              AS Currency,
	|	CommercialProposalForCustomer.PriceIncludesVAT                     AS PriceIncludesVAT,
	|	CommercialProposalForCustomer.Taxation                     AS ConsiderVAT,
	|	CommercialProposalForCustomer.DeliveryTermsText                AS DeliveryTerms,
	|	CommercialProposalForCustomer.PaymentTermsText                  AS PaymentTerm,
	|	CommercialProposalForCustomer.OtherAdditionalInformationText AS OtherConditions,
	|	CommercialProposalForCustomer.Client                              AS Client,
	|	CommercialProposalForCustomer.Counterparty                          AS Counterparty,
	|	CommercialProposalForCustomer.OptionToSpecifyDeliveryTerm        AS OptionToSpecifyDeliveryTerm,
	|	CommercialProposalForCustomer.PartialSaleAllowed             AS PartialSaleAllowed
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|WHERE
	|	CommercialProposalForCustomer.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                                   AS Ref,
	|	Goods.LineNumber                                              AS LineNumber,
	|	Goods.Products                                             AS Products,
	|	Goods.Characteristic                                           AS Characteristic,
	|	Goods.ManualDiscount + Goods.DiscountMarkupAmount     AS DiscountAmount,
	|	Goods.PercentRateOfManualDiscount + Goods.PercentRateOfAutomaticDiscountMarkup AS DiscountPercentage,
	|	&UnitConditions                                        AS UnitOfMeasure,
	|	Goods.Count                                               AS Count,
	|CASE
	|	WHEN &DisplayDiscounts_
	|		THEN Goods.Price
	|	ELSE CASE
	|			WHEN Goods.Count = 0
	|				THEN 0
	|			ELSE Goods.Sum / Goods.Count
	|		END
	|END                                                              AS Price,
	|	Goods.AmountIncludingVAT                                                AS AmountIncludingVAT,
	|	Goods.Sum                                                    AS Sum,
	|	Goods.VATAmount                                                 AS VATAmount,
	|	Goods.DeliveryPeriodDays                                             AS DeliveryPeriodDays
	|FROM
	|	Document.CommercialProposalForCustomer.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	
	UnitConditions = "Goods.UnitOfMeasure";
	CommercialProposalsDocumentsOverridable.GetTextOfRequestToGetUnitOfMeasurement(UnitConditions);
	Query.Text = StrReplace(Query.Text, "&UnitConditions", UnitConditions);
	
	RequestResultsPackage = Query.ExecuteBatch(); // Array of QueryResultSelection
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",   RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByProducts", RequestResultsPackage[1]);
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion


// Gets attached with a non-empty CID.
//
// Parameters:
//  FilesOwner - DocumentRef.CommercialProposalForCustomer - the document whose attachments are received.
//
// Returns:
//   ValueTable   - a table with information about email attachments with a non-empty identifier:
//     * Ref - CatalogRef.CommercialProposalForCustomerAttachedFiles
//     * Description - String
//     * Size - Number
//     * CIDAttachHTML - String
//
Function AttachedFilesWithNonEmptyCID(FilesOwner) Export

	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	AttachedFiles.Ref          AS Ref,
	|	AttachedFiles.Description    AS Description,
	|	AttachedFiles.Size          AS Size,
	|	AttachedFiles.CIDAttachHTML AS CIDAttachHTML
	|FROM
	|	Catalog.CommercialProposalForCustomerAttachedFiles AS AttachedFiles
	|WHERE
	|	AttachedFiles.FileOwner = &FilesOwner
	|	AND (NOT AttachedFiles.DeletionMark)
	|	AND AttachedFiles.CIDAttachHTML <> """"";
	
	Query.SetParameter("IsBlankString","");
	Query.SetParameter("FilesOwner",FilesOwner);
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndIf