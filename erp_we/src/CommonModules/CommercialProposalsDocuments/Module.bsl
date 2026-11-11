////////////////////////////////////////////////////////////////////////////////
// Subsystem "Commercial offers documents".
// General module.Commercial Proposals and documents
////////////////////////////////////////////////////////////////////////////////
//

#Region Public



//
// Enables functional options for all embedded documents in the commercial Offers documents subsystem.
//
// Parameters:
//   Parameters - Structure - Update Processing Status - contains the fields:
//    * ExecutionProgress - Structure - update processing progress - contains fields:
//       ** ProcessedObjectsCount1 - Number - the number of processed objects.
//       ** TotalObjectCount - Number - the number of objects to be processed.
//    * ProcessingCompleted - Boolean - Indicates that update processing is complete
//
Procedure EstablishUseOfCommercialOffers(Parameters = Undefined) Export
	
	If Parameters = Undefined Then
		ExecutionProgress = New Structure("ProcessedObjectsCount1, TotalObjectCount");
		Parameters = New Structure();
		Parameters.Insert("ExecutionProgress", ExecutionProgress);
		Parameters.Insert("ProcessingCompleted");
	EndIf;	
	
	ProgressMarkParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	Parameters.ExecutionProgress.TotalObjectCount = 0;
	ObjectsWithIssuesCount   = 0;
	ProcessedObjects_ = 0;
	
	SetPrivilegedMode(True);
	
	
	
	// ElectronicInteraction.CommercialProposalForCustomer
	
	SubsystemExists = Common.SubsystemExists(
		"ElectronicInteraction.CommercialProposals.CommercialProposalsDocuments.CommercialProposalForCustomer");
	
	If SubsystemExists Then
		Parameters.ExecutionProgress.TotalObjectCount = Parameters.ExecutionProgress.TotalObjectCount + 1;
		
		ObjectMetadata = Metadata.Constants.UseCommercialProposalsForCustomers;
		FullObjectName = ObjectMetadata.FullName();
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Write = False;
			
			Manager = Constants["UseCommercialProposalsForCustomers"].CreateValueManager();
			Manager.Read();
			
			If Not Manager.Value Then
				Manager.Value = True;
				Write = True;
			EndIf;
			
			If Write Then
				InfobaseUpdate.WriteData(Manager);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Manager, ProgressMarkParameters);
			EndIf;
			
			ProcessedObjects_ = ProcessedObjects_ + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			MessageText = NStr("vi = 'Không thể xử lý hằng ""Sử dụng báo giá cho khách hàng"" do nguyên nhân:';
								|ru = 'Не удалось обработать константу ""Использовать коммерческие предложения клиентам"" по причине:';
								|en = 'Cannot process the constant ""Use sales quotations"". Reason:'; fa = 'Cannot process the constant ""Use sales quotations"". Reason:';
								|it = 'Non è stato possibile elaborare una costante ""Utilizzare le richieste di offerte commerciali dai clienti"" a causa di:';
								|pl = 'Nie udało się przetworzyć stałą ""Używać oferty komercyjne dla klientów"" z powodu:';
								|tr = '""Müşteri satış tekliflerinin kullanımı"" sabiti şu sebeple işlenemedi:'") 
				+ Chars.LF + DetailErrorDescription(ErrorInfo());
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				ObjectMetadata,, MessageText);
			
		EndTry;
		
	EndIf;
	
	// End ElectronicInteraction.CommercialProposalForCustomer
	
	
	If ProcessedObjects_ = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = NStr("vi = 'Không thể xử lý tất cả các hằng của phân hệ báo giá.';
							|ru = 'Не удалось обработать все константы подсистемы коммерческих предложений.';
							|en = 'Cannot process all constants of the sales quotation subsystem.'; fa = 'Cannot process all constants of the sales quotation subsystem.';
							|it = 'Non è stato possibile elaborare tutte le costanti del sottosistema delle offerte commerciali';
							|pl = 'Nie udało się przetworzyć wszystkie stałe podsystemu ofert komercyjnych.';
							|tr = 'Satış teklifi alt sistemlerinin tüm sabitleri işlenemedi.'");
		Raise MessageText;
	Else
		MessageText = NStr("vi = 'Đã xử lý tất cả các hằng của phân hệ báo giá.';
							|ru = 'Обработаны все константы подсистемы коммерческие предложения.';
							|en = 'All constants of the sales quotation subsystem are processed.'; fa = 'All constants of the sales quotation subsystem are processed.';
							|it = 'Tutte le costanti del sottosistema offerte commerciali sono state elaborate';
							|pl = 'Zostały przetworzone wszystkie stałe podsystemu oferty komercyjne.';
							|tr = 'Satış teklifi alt sistemlerinin tüm sabitlerinin işlenmesi.'");
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,,,
			MessageText);
	EndIf;

	Parameters.ExecutionProgress.ProcessedObjectsCount1 = ProcessedObjects_;
	
	Parameters.ProcessingCompleted = (ProcessedObjects_ = Parameters.ExecutionProgress.TotalObjectCount);
	
EndProcedure

// It is used for creating accounting settings in the application configuration
//
// Returns:
//  Structure - contains fields:
//  * SingleOrganizationIsUsed                  - Boolean - indicates that only one organization is used in the configuration.
//  * SoleCompany                              - DefinedType.Organization - the value of the only organization in the IB.
//  * SingleCurrencyIsUsed                       - Boolean - indicates that the configuration uses only one currency.
//  * OnlyCurrency                                   - CatalogRef.Currencies - the value of a single currency in the IB.
//  * PartnersAreUsed                                 - Boolean - indicates that partners are being used.
//  * IndependentManagementOfPartnersAndCounterparties             - Boolean - indicates that partners and counterparties are independently managed.
//  * ProductCharacteristicsAreUsed               - Boolean - indicates that the item's characteristics are being used.
//  * TypeOfContactInformationEmailManager                - CatalogRef.ContactInformationKinds - to define the Manager's email address as a contact person.
//  * TypeOfContactInformationManagerSPhoneNumber              - CatalogRef.ContactInformationKinds - to identify the Manager's phone number as a contact person.
//  * TypesOfPricesAreUsed                                  - Boolean - indicates that price types are used.
//  * ManualDiscountsAreUsedInSales                    - Boolean - indicates that manual discounts are used in sales.
//  * AutomaticDiscountsInSalesAreUsed            - Boolean - indicates that automatic discounts are used in sales.
//  * AssignableAutomaticDiscountsInSalesAreUsed - Boolean - indicates that automatic sales discounts are being assigned.
//  * ImplementedFormForViewingDiscounts                      - Boolean - indicates that the discount viewing form can be called.
//  * ImplementedFillingInPricesAccordingToSalesConditions             - Boolean - indicates that prices were filled in according to the terms of sale.
//  * ImplementedFillingPricesByTypeOfPrices                   - Boolean - indicates that filling in prices by price type has been implemented.
//  * ImplementedFillingInPaymentTerms                   - Boolean - indicates that the payment terms have been completed.
//  * ImplementedFillingInDeliveryTerms                 - Boolean - indicates that the delivery terms have been filled in.
//  * ImplementedSelectionOfProducts                         - Boolean - indicates that the item selection was implemented.
//  * ImplementedBarcodeSearch                           - Boolean - indicates that the product search by barcode is implemented.
//  * ImplementedStringSplitting                            - Boolean - indicates that line splitting is implemented in PM Products.
//  * ImplementedLoadingTSDData                         - Boolean - indicates that data loading is implemented using the TSD in PM Products.
//  * ImplementedFillingInDocumentsFromExternalFile       - Boolean - indicates that filling in PM Products from an external file is implemented.
//  * StatusOfCommercialOffersToClientsIsUsed   - Boolean - indicates that the status of commercial offers to customers is used.
//  * StatesOfCommercialOffersToClientsAreUsed - Boolean - indicates that the status of commercial offers to customers has been implemented.
//  * DetailsOfCounterpartySProductOwner         - String - name of the "client's Commercial offer" document detail that contains the owner of the counterparty's item.
//  * StatusOfCommercialOffersToClientsDraft       - Array - defines the statuses in which the commercial offer is considered a draft.
//  * StatusesOfCommercialOffersToCustomersAreValid      - Array - defines the statuses in which the commercial offer is considered valid.
//  * UsePurchaseOrders                        - Boolean - indicates that orders to suppliers are being used.
//  * UseSETPBidzaarIntegrationForBuyers      - Boolean - indicates that integration with BIdzaar ETP is being used for buyers.
//
Function AccountingSettings() Export
	
	Settings = New Structure;
	
	Settings.Insert("SingleOrganizationIsUsed",       False);
	Settings.Insert("SoleCompany",                   Undefined);
	
	Settings.Insert("SingleCurrencyIsUsed",            False);
	Settings.Insert("OnlyCurrency",                        Undefined);
	
	Settings.Insert("PartnersAreUsed",                      False);
	Settings.Insert("IndependentManagementOfPartnersAndCounterparties",  True);
	Settings.Insert("ProductCharacteristicsAreUsed",    False);
	
	Settings.Insert("TypeOfContactInformationEmailManager",     Catalogs.ContactInformationKinds.UserEmail);
	Settings.Insert("TypeOfContactInformationManagerSPhoneNumber",   Catalogs.ContactInformationKinds.UserPhone);

#Region CommercialProposalsForCustomers
	
	Settings.Insert("TypesOfPricesAreUsed",                                  False);
	Settings.Insert("ManualDiscountsAreUsedInSales",                    False);
	Settings.Insert("AutomaticDiscountsInSalesAreUsed",            False);
	Settings.Insert("AssignableAutomaticDiscountsInSalesAreUsed", False);
	Settings.Insert("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments",False);
	Settings.Insert("DoNotDisplayDiscountsInSalesDocuments",                   False);
	Settings.Insert("ImplementedFormForViewingDiscounts",                      False);
	Settings.Insert("ImplementedFillingInPricesAccordingToSalesConditions",             False);
	Settings.Insert("ImplementedFillingPricesByTypeOfPrices",                   False);
	Settings.Insert("ImplementedFillingInPaymentTerms",                   False);
	Settings.Insert("ImplementedFillingInDeliveryTerms",                 False);
	Settings.Insert("ImplementedSelectionOfProducts",                         False);
	Settings.Insert("ImplementedBarcodeSearch",                           False);
	Settings.Insert("ImplementedStringSplitting",                            False);
	Settings.Insert("ImplementedLoadingTSDData",                         False);
	Settings.Insert("ImplementedFillingInDocumentsFromExternalFile",       False);
	Settings.Insert("DetailsOfCounterpartySProductOwner",         "");
	Settings.Insert("StatusOfCommercialOffersToClientsDraft",       New Array);
	Settings.Insert("StatusesOfCommercialOffersToCustomersAreValid",      New Array);
	Settings.Insert("StatusOfCommercialOffersToClientsIsUsed",   False);
	Settings.Insert("StatesOfCommercialOffersToClientsAreUsed", False);

#EndRegion

#Region SupplierSCommercialOffer

	Settings.Insert("RegisterSupplierPrices", False);
	Settings.Insert("UsePurchaseOrders", True);
	Settings.Insert("UseSETPBidzaarIntegrationForBuyers", False);

#EndRegion

	CommercialProposalsDocumentsOverridable.WhenDefiningAccountingSettings(Settings);
	
	Return Settings;
	
EndFunction

// Formalizes the source name of the subordinate commercial offer in the context of a specific document
// Request for a commercial offer.
//
// Returns:
//  String - name of the offer source
//
Function SourceNameSubordinateBusinessOffers() Export
	
	Return "CommercialOffersFromSupplier";
	
EndFunction

// Formalizes the name of the source of the commercial offer that is not subordinate to the document Request for a commercial offer,
// in the context of which the offers are analyzed.
//
// Returns:
//  String - name of the offer source
//
Function SourceNameOtherCommercialOffers() Export
	
	Return "OtherCommercialOffersFromSupplier";
	
EndFunction


#Region WorkingWithHTML5

// Retrieves the Dochtml object from the HTML text.
//
// Parameters:
//  HTMLText  - String - text in HTML format.
//  Encoding  - String - if set, the HTML document Declaration will contain
//      the encoding attribute with the specified value.
//
// Returns:
//   HTMLDocument - the created HTML document.
//
Function HTMLDocumentObjectFromHTMLText(HTMLText, Encoding = Undefined) Export
	
	Builder = New DOMBuilder;
	HTMLReader = New HTMLReader;
	
	NewHTMLText = HTMLText;
	PositionOpenXML = StrFind(NewHTMLText,"<?xml");
	
	If PositionOpenXML > 0 Then
		
		PositionCloseXML = StrFind(NewHTMLText,"?>");
		If PositionCloseXML > 0 Then
			
			NewHTMLText = Left(NewHTMLText,PositionOpenXML - 1) + Right(NewHTMLText,StrLen(NewHTMLText) - PositionCloseXML -1);
			
		EndIf;
		
	EndIf;
	
	If Encoding = Undefined Then
		
		HTMLReader.SetString(HTMLText);
		
	Else
		
		Try
		
			HTMLReader.SetString(HTMLText, Encoding);
		
		Except
			
			HTMLReader.SetString(HTMLText);
			
		EndTry;
		
	EndIf;
	
	Return Builder.Read(HTMLReader);
	
EndFunction

// Processes HTML text to be placed in a formatted document.
//
// Parameters:
//  FilesOwner    - DocumentRef - the document whose attached files need to be processed.
//  HTMLText         - String - the HTML text being processed.
//  AttachmentsStructure - Structure - the structure in which images are placed-email attachments.
//
// Returns:
//   String   - processed HTML text.
//
Function ProcessedHTMLTextForFormattedDocument(FilesOwner, HTMLText, AttachmentsStructure) Export
	
	If Not IsBlankString(HTMLText) Then
		
		HTMLDocument = HTMLDocumentObjectFromHTMLText(HTMLText);
		
		FileOwnerName_ = FilesOwner.Metadata().Name;
		
		TableOfFiles = Documents[FileOwnerName_].AttachedFilesWithNonEmptyCID(FilesOwner);
		
		If TableOfFiles.Count() Then
			
			For Each AttachedFile In TableOfFiles Do
				
				For Each Picture In HTMLDocument.Images Do
					
					AttributePictureSource = Picture.Attributes.GetNamedItem("src");
					
					If StrOccurrenceCount(AttributePictureSource.Value, AttachedFile.CIDAttachHTML) > 0 Then
						
						NewAttributePicture = AttributePictureSource.CloneNode(False);
						NewAttributePicture.TextContent = AttachedFile.Description;
						Picture.Attributes.SetNamedItem(NewAttributePicture);
						
						RefToBinaryFileData = FilesOperations.FileData(AttachedFile.Ref).RefToBinaryFileData;
						AttachmentsStructure.Insert(AttachedFile.Description, New Picture(GetFromTempStorage(RefToBinaryFileData)));
						
						Break;
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
			Return HTMLTextFromHTMLDocumentObject(HTMLDocument);
			
		Else
			
			Return HTMLText;
			
		EndIf;
		
	Else
		
		Return HTMLText;
		
	EndIf;
	
EndFunction

// Replaces the names of images in the HTML document with the CID of attachments.
// Parameters:
//  HTMLDocument - HTMLDocument - the HTML document in which the replacement will be performed.
//  MapsTable - ValueTable - table of file name and ID matches.
//
Procedure ReplaceImageNamesWithHTMLAttachmentCIDs(HTMLDocument, MapsTable) Export
	
	MapsTable.Indexes.Add("FileName");
	
	For Each Picture In HTMLDocument.Images Do
		
		AttributePictureSource = Picture.Attributes.GetNamedItem("src");
		
		FoundRow = MapsTable.Find(AttributePictureSource.TextContent,"FileName");
		If FoundRow <> Undefined Then
			
			NewAttributePicture = AttributePictureSource.CloneNode(False);
			NewAttributePicture.TextContent = String("cid:"+FoundRow.CID);
			Picture.Attributes.SetNamedItem(NewAttributePicture);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Retrieves text from an HTML document.
//
// Parameters:
//  HTMLDocument - HTMLDocument - an HTML document to convert to a string.
//
// Returns:
//   String - processed HTML text.
//
Function HTMLTextFromHTMLDocumentObject(HTMLDocument) Export
	
	Try
		DOMWriter = New DOMWriter;
		HTMLWriter = New HTMLWriter;
		HTMLWriter.SetString();
		DOMWriter.Write(HTMLDocument,HTMLWriter);
		Return HTMLWriter.Close();
	Except
		Return "";
	EndTry;
	
EndFunction

// Writes an email attachment located in temporary storage to a file.
//
// Parameters:
//  FilesOwner                 - DefinedType.AttachedFilesOwner - the file folder or object
//                                                                                  to attach the file to.
//  AddressInTempStorage - String - an address that points to binary data in temporary storage.
//  FileName                  - String - file name.
// 
// Returns:
//  DefinedType.AttachedFile - a link to the created attached file.
//
Function RecordAttachmentFromTemporaryStorage(FilesOwner, AddressInTempStorage, FileName) Export
	
	FileNameToParse = FileName;
	ExtensionWithoutPoint = CommonClientServer.GetFileNameExtension(FileNameToParse);
	BaseName   = CommonClientServer.ReplaceProhibitedCharsInFileName(FileNameToParse);
	
	FileParameters = New Structure;
	FileParameters.Insert("FilesOwner",              FilesOwner);
	FileParameters.Insert("Author",                       Undefined);
	FileParameters.Insert("BaseName",            BaseName);
	FileParameters.Insert("ExtensionWithoutPoint",          ExtensionWithoutPoint);
	FileParameters.Insert("Modified",              Undefined);
	FileParameters.Insert("ModificationTimeUniversal", Undefined);
	Return FilesOperations.AppendFile(FileParameters, AddressInTempStorage);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export

	CheckProcedureName = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	CommentTemplate = "%1 %2.";
	
	
EndProcedure

// Registers new options for standard reports
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterReportOptions(Parameters) Export
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		CustomizeReportsOptions(Undefined);
	EndIf;
	
	Parameters.ProcessingCompleted =
	InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "");
	
EndProcedure

// Configures options for standard reports
// 
// Parameters:
//  Settings - See ReportsOptionsOverridable.CustomizeReportsOptions
//
Procedure CustomizeReportsOptions(Settings = Undefined) Export
	
	DescriptionOfReport = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.Surveys") Then
		If Settings = Undefined Then
			DescriptionOfReport = New Structure;
			FullReportName = Metadata.Reports.SurveysAnalyticalReport.FullName();
			Report = Catalogs.MetadataObjectIDs.FindByAttribute("FullName", FullReportName);
			DescriptionOfReport.Insert("Report", Report);
		Else
			DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SurveysAnalyticalReport);
		EndIf;
	EndIf;
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Checks the completeness of the verified details.
//
// Parameters:
//   Document                  - DocumentRef - the document that the input is based on.
//   HasErrorsDeletionMark - Boolean         - if True - the document on the basis of which the input is made is not carried out or marked for deletion.
//   Status                    - Arbitrary   - The status of the document that is used for input.
//   ThereAreErrorsStatus          - Boolean         - if True, the document used for input has an incorrect status.
//   ArrayOfValidStatuses  - Array         - list of acceptable statuses.
//
Procedure CheckPossibilityOfEnteringBasedOn(Document,
	                                           HasErrorsDeletionMark,
	                                           Status = Undefined,
	                                           ThereAreErrorsStatus = False,
	                                           ArrayOfValidStatuses = Undefined) Export
	
	If HasErrorsDeletionMark Then
		
		ErrorText = StrTemplate(NStr("vi = 'Chứng từ %1đã bị đặt dấu xóa. Cấm nhập trên cơ sở chứng từ bị đặt dấu xóa.';
									|ru = 'Документ %1 помечен на удаление. Ввод на основании помеченного на удаление документа запрещен.';
									|en = 'The document %1 is marked for deletion. Cannot use the input on basis of the document marked for deletion.'; fa = 'The document %1 is marked for deletion. Cannot use the input on basis of the document marked for deletion.';
									|it = 'Il documento %1 è stato selezionato per eliminazione. Non è consentito inserire dati in base al documento selezionato per eliminazione.';
									|pl = 'Dokument %1 został oznaczony do usunięcia. Wprowadzanie na podstawie oznaczonego do usunięcia dokumentu jest zabronione.';
									|tr = 'Belge %1 silinenlere etiketlendi. Silinen belgelerdeki etiketin temellendirildiği girdi yasak.'"),
		                        Document);
	
		Raise ErrorText;
		
	ElsIf ThereAreErrorsStatus Then
		
		If Not ValueIsFilled(ArrayOfValidStatuses) Then
			ErrorText = StrTemplate(NStr("vi = 'Chứng từ %1 đang có trạng thái ""%2"". Cấm nhập trên cơ sở.';
										|ru = 'Документ %1 находится в статусе ""%2"". Ввод на основании запрещен.';
										|en = 'The document %1 is in the ""%2"" status. Input on basis is prohibited.'; fa = 'The document %1 is in the ""%2"" status. Input on basis is prohibited.';
										|it = 'Il documento %1 si trova nello stato ""%2"" Non è consentito inserire dati in base al documento.';
										|pl = 'Dokument %1 jest w statusie ""%2"". Wprowadzanie na podstawie jest zabronione.';
										|tr = 'Belge %1 ""%2"" durumundadır. Temellendirmedeki girdi yasak.'"),
			                        Document,
			                        Status);
			
		ElsIf TypeOf(ArrayOfValidStatuses) = Type("Array") Then
			
			If ArrayOfValidStatuses.Count() = 1 Then
				
				StringOfAcceptableStatuses = ArrayOfValidStatuses[0];
				
				ErrorText = StrTemplate(NStr("vi = 'Chứng từ %1 đang có trạng thái ""%2"". Chỉ được phép nhập trên cơ sở với trạng thái ""%3"".';
											|ru = 'Документ %1 находится в статусе ""%2"". Ввод на основании разрешен только в статусе ""%3"".';
											|en = 'Document %1 is in the ""%2"" status. Input on basis is allowed only in the ""%3"" status.'; fa = 'Document %1 is in the ""%2"" status. Input on basis is allowed only in the ""%3"" status.';
											|it = 'Il documento%1 si trova nello stato ""%2"". L''inserimento è consentito solo nello stato ""%3"".';
											|pl = 'Dokument %1 jest w statusie ""%2"". Wprowadzanie na podstawie jest dozwolone tylko w statusie ""%3"".';
											|tr = 'Belge %1 ""%2"" durumundadır. Temellendirmedeki girdiye sadece ""%3"" durumunda izin verilir.'"),
				                        Document,
				                        Status,
				                        StringOfAcceptableStatuses);
			
			Else
				
				StringOfAcceptableStatuses = StrConcat(ArrayOfValidStatuses, """, """);
				
				ErrorText =StrTemplate(NStr("vi = 'Chứng từ %1 đang có trạng thái ""%2"". Chỉ được phép nhập trên cơ sở với các trạng thái ""%3"".';
											|ru = 'Документ %1 находится в статусе ""%2"". Ввод на основании разрешен только в статусах ""%3"".';
											|en = 'The document %1 is in the ""%2"" status. Input on basis is allowed only in ""%3"" statuses.'; fa = 'The document %1 is in the ""%2"" status. Input on basis is allowed only in ""%3"" statuses.';
											|it = 'Il documento %1 si trova nello stato ""%2"". L''inserimento sulla base del documento è consentito solo nello stato ""%3"".';
											|pl = 'Dokument %1 jest w statusie ""%2"". Wprowadzanie na podstawie jest dozwolone tylko w statusach ""%3"".';
											|tr = 'Belge %1 ""%2"" durumundadır. Temellendirmedeki girdiye sadece ""%3"" durumlarında izin verilir.'"),
				                            Document,
					                        Status,
					                        StringOfAcceptableStatuses);;
			EndIf;
			
		EndIf;
	
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

// To save changes in sources in the analysis of the queries.
// Parameters:
//  OperationParametersList - Structure - The operation parameters.
//  ResultAddress   - String    - Address of the result response.
//
Procedure SaveUserChangesInSourceDocuments(OperationParametersList, ResultAddress) Export
	
	Cancel = False;
	
	Sources = OperationParametersList.Sources;
	
	CommercialProposalsDocumentsOverridable.SaveUserChangesInSourceDocuments(Sources, Cancel);
	
	PutToTempStorage(Cancel, ResultAddress);
	
EndProcedure

// Sets the conditional registration for the "VAT rate", "VAT amount", "VAT amount" for taxation.
//
// Parameters:
//  Form                 - ClientApplicationForm - the form for which the conditional design is set.
//  NameOfVATRateField - String - The name of the form element containing the VAT rate, if it differs from the "Touristland".
//  NameOfVATAmountField  - String - The name of the form element that contains the amount of VAT if it is different from "Tourismand"
//  NameOfFieldWithVATAmount - String - The name of the form element that contains the amount including VAT,
//                                   if it is different from "Tourismand"
//
Procedure EstablishConditionalAppearanceOfVATAmounts(Form,
	                                          NameOfVATRateField = "GoodsVATRate",
	                                          NameOfVATAmountField  = "GoodsVATAmount",
	                                          NameOfFieldWithVATAmount = "GoodsAmountIncludingVAT") Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	VATRateInputField = Form.Items[NameOfVATRateField]; // FormField
	ItemField.Field = New DataCompositionField(VATRateInputField.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	VATAmountField = Form.Items[NameOfVATAmountField]; // FormField
	ItemField.Field = New DataCompositionField(VATAmountField.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FieldForEnteringAmountWithVAT = Form.Items[NameOfFieldWithVATAmount]; // FormField
	ItemField.Field = New DataCompositionField(FieldForEnteringAmountWithVAT.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Taxation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

// Setting the conditional design for the "amount with VAT" field, depending on the "price includes"flag.
//
// Parameters:
//  Form                 - ClientApplicationForm - the form for which the conditional design is set.
//  NameOfFieldWithVATAmount - String - The name of the form element that contains the amount including VAT, if it is different from "Tourismand".
//
Procedure SetConditionalAppearancePriceIncludesVAT(Form, NameOfFieldWithVATAmount = "GoodsAmountIncludingVAT") Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items; // FormItems
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	VATAmountField_ = FormItems[NameOfFieldWithVATAmount]; // FormField
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(VATAmountField_.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.PriceIncludesVAT");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

// Creates a representation of the base document on the form, if the base document is a request.
//
// Parameters:
//  DocumentBasis - DocumentRef - Link to the Foundation document.
//
// Returns:
//   String
//
Function PresentationOfBasisOnRequest(DocumentBasis) Export

	QueryData = Undefined;
	
	
	
	If QueryData = Undefined Then
		Return "";
	EndIf;
	
	TextDocumentBase = String(DocumentBasis);
	
	RowsArray = New Array;
	
	HyperlinkText = "OpenQueryDocument";
	
	StringBaseDocument = New FormattedString(
		        TextDocumentBase,
		        New Font(,,,,True),
		        StyleColors.EDLHyperlinkColor,
		        ,
		        HyperlinkText);
	
	RowsArray.Add(StringBaseDocument);
	
	PointIsRequired = False;
	
	If ValueIsFilled(QueryData.PublicationEndDate) Then
		
		PointIsRequired = True;
		
		RowsArray.Add(", ");
		RowsArray.Add(NStr("vi = 'nhận trước';
							|ru = 'принимается до';
							|en = 'accepted before'; fa = 'accepted before';
							|it = 'si accetta entro';
							|pl = 'przyjmuje się do';
							|tr = 'önce gerçekleştirilir'"));
		RowsArray.Add(" ");
		
		RowsArray.Add(New FormattedString(
		        Format(QueryData.PublicationEndDate, "DLF=D"),
		        New Font(,,True)));
		
	EndIf;
	
	If ValueIsFilled(QueryData.ReviewEndDate) Then
		
		PointIsRequired = True;
		
		RowsArray.Add(", ");
		RowsArray.Add(NStr("vi = 'xem xét trước';
							|ru = 'рассматривается до';
							|en = 'reviewed before'; fa = 'reviewed before';
							|it = 'si valuta entro';
							|pl = 'rozpatruje się do';
							|tr = 'önce değerlendirilir'"));
		RowsArray.Add(" ");
		
		RowsArray.Add(New FormattedString(
		        Format(QueryData.ReviewEndDate, "DLF=D"),
		        New Font(,,True)));
		
	EndIf;
	
	If PointIsRequired Then
		RowsArray.Add(".");
	EndIf;
	
	Return New FormattedString(RowsArray);
	
EndFunction

// Forms a representation of the base document on the form.
//
// Parameters:
//  DocumentBasis - DocumentRef - Link to the Foundation document.
//
// Returns:
//   String
//
Function BaseDocumentPresentation(DocumentBasis) Export
	
	HyperlinkText = "OpenDocument_";
	
	Return New FormattedString(
	        String(DocumentBasis),
	        New Font(,,,,True),
	        StyleColors.EDLHyperlinkColor,
	        ,
	        HyperlinkText);
	
EndFunction

// Determines whether a comment is present in a row in the table part
//
// Parameters:
//  Form             - ClientApplicationForm - the form for which actions are performed.
//  TabularSectionName - String - the table part for which actions are performed.
//  AttributeName1     - String - name of the first PM prop that can contain a comment.
//  AttributeName2     - String - name of the second PM prop that can contain a comment.
//  PropsNameHasComment - String - name of the Boolean attribute that indicates whether a comment is present in the string.
//
Procedure DetectPresenceOfCommentsInLines(Form, TabularSectionName, AttributeName1, AttributeName2, PropsNameHasComment) Export
	
	For Each TSRow In Form.Object[TabularSectionName] Do
		
		TSRow[PropsNameHasComment] = Not IsBlankString(TSRow[AttributeName1])
		                                        Or Not IsBlankString(TSRow[AttributeName2]);
		
	EndDo;
	
EndProcedure

// Generates a view of contact information for one of the types or types.
//
// Parameters:
//  ContactInformationTable1 - ValueTable    - contains contact information.
//  TypeTypeOfContactInformation  - EnumRef.ContactInformationTypes, CatalogRef.ContactInformationKinds - type or type of contact information.
//  Separator                 - String - how the different values of the CI will be separated in the view.
//
// Returns:
//   String
//
Function PresentationOfContactInformationFromTable(ContactInformationTable1, TypeTypeOfContactInformation, Separator = "; ") Export
	
	FIlter_By_Type = False;
	FilterByType = False;
	
	If ValueIsFilled(TypeTypeOfContactInformation) Then
		If TypeOf(TypeTypeOfContactInformation) = Type("EnumRef.ContactInformationTypes") Then
			FIlter_By_Type = True;
		ElsIf TypeOf(TypeTypeOfContactInformation) = Type("CatalogRef.ContactInformationKinds") Then
			FilterByType = True;
		EndIf;
	EndIf;
	
	FirstPass = True;

	For Each ContactInformationRecord In ContactInformationTable1 Do
		
		If FilterByType And ContactInformationRecord.Kind <> TypeTypeOfContactInformation Then
			Continue;
		ElsIf FIlter_By_Type And ContactInformationRecord.Type <> TypeTypeOfContactInformation Then
			Continue;
		EndIf;
		
		If FirstPass Then
			Presentation = ContactInformationRecord.Presentation;
			FirstPass = False;
		Else
			Presentation = Presentation + Separator + ContactInformationRecord.Presentation;
		EndIf;
	EndDo;
	
	Return Presentation;
	
EndFunction

// Forms a representation of the organization that is interacting with the commercial offer.
//
// Parameters:
//  Partner    - DefinedType.PartnerOfEDL    - partner of the document.
//  Counterparty - DefinedType.EDLCounterparty - counterparty of the document.
//
// Returns:
//   String
//
Function PresentationOfCounterpartySPartner(Partner, Counterparty) Export
	
	PresentationOfCounterpartySPartner = "";
	StandardProcessing = True;
	
	CommercialProposalsDocumentsOverridable.UponReceiptOfPresentationOfCounterpartySPartner(PresentationOfCounterpartySPartner, Partner, Counterparty, StandardProcessing);
	
	If StandardProcessing Then
		
		If ValueIsFilled(Partner) Then
			Return String(Partner);
		Else
			Return String(Counterparty);
		EndIf;
		
	Else
		Return PresentationOfCounterpartySPartner;
	EndIf;
	
EndFunction

// Forms a representation of the offer's expiration date.
//
// Parameters:
//  ThereAreDiscounts   - Boolean - availability of discounts in the document.
//  ValidityPeriod - Date - the validity of the proposal.
//
// Returns:
//   String
//
Function PresentationOfExpirationDateForPrinting(ThereAreDiscounts, ValidityPeriod) Export

	PresentationOfValidityPeriod = "";
	
	If ValueIsFilled(ValidityPeriod) Then
		
		If ThereAreDiscounts Then
			MessageTemplate = NStr("vi = 'Giá chỉ định và chiết khấu có hiệu lực đến %1';
									|ru = 'Указанные цены и скидки действуют до %1';
									|en = 'These prices and discounts are valid before %1'; fa = 'These prices and discounts are valid before %1';
									|it = 'Prezzi e sconti specificati sono validi fino a %1';
									|pl = 'Przedstawione ceny i rabaty obowiązują do %1';
									|tr = 'Belirtilen fiyatlar ve indirimler %1 tarihine kadar geçerli'");
		Else
			MessageTemplate = NStr("vi = 'Giá chỉ định có hiệu lực đến %1';
									|ru = 'Указанные цены действуют до %1';
									|en = 'These prices are valid before %1'; fa = 'These prices are valid before %1';
									|it = 'I prezzi indicati sono validi entro%1';
									|pl = 'Przedstawione ceny obowiązują do %1';
									|tr = 'Belirtilen fiyatlar %1 tarihine kadar geçerli'");
		EndIf;
		
		PresentationOfValidityPeriod = StrTemplate(MessageTemplate, Format(ValidityPeriod, "DLF=DD"));
		
	EndIf;
	
	Return PresentationOfValidityPeriod;
	
EndFunction

// Creates a representation of the possibility of partial purchase of goods on offer.
//
// Parameters:
//  PartialSaleAllowed - Boolean  - payment terms for the document.
//
// Returns:
//   String
//
Function PresentationOfPartialRedemptionForPrinting(PartialSaleAllowed) Export
	
	If PartialSaleAllowed Then
		Return NStr("vi = 'Không bắt buộc mua tất cả hàng hóa trong đề xuất.';
					|ru = 'Покупка всех товаров предложения не обязательна.';
					|en = 'It is not necessary to purchase all goods of the quotation.'; fa = 'It is not necessary to purchase all goods of the quotation.';
					|it = 'L''acquisto di tutte le merci dell''offerta non è obbligatorio.';
					|pl = 'Zakup wszystkich towarów z oferty nie jest konieczne.';
					|tr = 'Teklif edilen tüm ürünlerin satın alınmaları gerekli değil.'");
	Else
		Return NStr("vi = 'Đơn giá có hiệu lực chỉ khi mua tất cả hàng trong đề xuất.';
					|ru = 'Цены действительны только при покупке всех товаров предложения.';
					|en = 'Prices are relevant only for the purchase of all products in the quotation.'; fa = 'Prices are relevant only for the purchase of all products in the quotation.';
					|it = 'I prezzi sono validi solo per l''acquisto di tutte le merci dell''offerta';
					|pl = 'Ceny obowiązują tylko przy zakupie wszystkich towarów z oferty.';
					|tr = 'Fiyatlar sadece teklifteki tüm ürünlerin satın alındığında geçerlidir'");
	EndIf;
	
EndFunction

// Creates a representation of the delivery terms for printing.
//
// Parameters:
//  PaymentTerm    - String  - payment terms for the document.
//  DeliveryTerms  - String  - delivery terms for the document.
//  OtherConditions    - String - other terms of delivery according to the document.
//
// Returns:
//   String - general presentation of the terms of delivery
//
Function PresentationOfDeliveryTermsForPrinting(PaymentTerm, DeliveryTerms, OtherConditions) Export

	PresentationOfTermsOfDelivery = "";
	
	If Not IsBlankString(PaymentTerm) Then
		PaymentTerm = StrTemplate(NStr("vi = 'Thanh toán: %1';
										|ru = 'Оплата: %1';
										|en = 'Payment: %1'; fa = 'Payment: %1';
										|it = 'Pagamento: %1';
										|pl = 'Płatność: %1';
										|tr = 'Ödeme: %1'"), PaymentTerm);
		PresentationOfTermsOfDelivery = PaymentTerm;
	EndIf;
	
	If Not IsBlankString(DeliveryTerms) Then
		
		DeliveryTerms = StrTemplate(NStr("vi = 'Giao hàng: %1';
										|ru = 'Доставка: %1';
										|en = 'Delivery: %1'; fa = 'Delivery: %1';
										|it = 'Consegna: %1';
										|pl = 'Dostawa: %1';
										|tr = 'Teslimat: %1'"), DeliveryTerms);
		PresentationOfTermsOfDelivery = PresentationOfTermsOfDelivery 
		                              + ?(IsBlankString(PresentationOfTermsOfDelivery), "", Chars.LF)
		                              + DeliveryTerms;
		
	EndIf;
	
	If Not IsBlankString(OtherConditions) Then
		
		If IsBlankString(PresentationOfTermsOfDelivery) Then
			OtherConditions = OtherConditions;
		Else
			OtherConditions = StrTemplate(NStr("vi = 'Khác: %1';
												|ru = 'Прочее: %1';
												|en = 'Other: %1'; fa = 'Other: %1';
												|it = 'Altro: %1';
												|pl = 'Inne: %1';
												|tr = 'Diğer: %1'"), OtherConditions);
		EndIf;
		
		PresentationOfTermsOfDelivery = PresentationOfTermsOfDelivery 
		                              + ?(IsBlankString(PresentationOfTermsOfDelivery), "", Chars.LF)
		                              + OtherConditions;
		
	EndIf;
	
	Return PresentationOfTermsOfDelivery;

EndFunction

// Generates a representation of the amounts to output to the printed form of the document
//
// Parameters:
//  HeaderData_      - QueryResultSelection, Structure - the object for which you want to determine whether contact information is available.
//  AmountTotal        - Number - the amount of the document with VAT.
//  AmountTotalVAT     - Number - the VAT amount of the document.
//  GoodsQuantity - Number - amount of goods.
//
// Returns:
//  Structure - contains fields:
//  * TotalString - String-  total line for the document amounts and items.
//  * AmountInWords  - String - a final line containing the amount of words.
//
Function PresentationOfDocumentAmountsForPrinting(HeaderData_, AmountTotal, AmountTotalVAT, GoodsQuantity) Export

	CurrencyPresentation = ?(ValueIsFilled(HeaderData_.Currency), TrimAll(HeaderData_.Currency), "");
	
	AmountToBeRegistered = AmountTotal + ?(HeaderData_.PriceIncludesVAT, 0, AmountTotalVAT);
	AmountInWords = CurrencyRateOperations.GenerateAmountInWords(AmountToBeRegistered, HeaderData_.Currency);
	
	TotalString = "";
	If HeaderData_.ConsiderVAT And Not HeaderData_.PriceIncludesVAT Then
		
		TotalString = StrTemplate(NStr("vi = 'Tổng cộng: %1 %2, thuế GTGT:%3 %2';
										|ru = 'Итого: %1 %2, сумма НДС: %3 %2';
										|en = 'Total: %1 %2, VAT amount: %3 %2'; fa = 'Total: %1 %2, VAT amount: %3 %2';
										|it = 'Totale: %1 %2, importo IVA: %3 %2';
										|pl = 'Łącznie: %1 %2, suma VAT: %3 %2';
										|tr = 'Toplam: %1 %2, KDV tutarı: %3 %2'"),
		                           Format(AmountTotal,"NFD=2; NDS=,"),
		                           CurrencyPresentation,
		                           Format(AmountTotalVAT,"NFD=2; NDS=,; NZ=0,00"));
		
		TotalString = TotalString + Chars.LF;
		
	EndIf;
	
	StringOfTotalTitles =  StrTemplate(NStr("vi = 'Tổng số mục: %1, thành tiền %2';
											|ru = 'Всего наименований: %1, на сумму %2';
											|en = 'Total items: %1, to the amount %2'; fa = 'Total items: %1, to the amount %2';
											|it = 'Totale articoli: %1, per importo di %2';
											|pl = 'Razem pozycji: %1, na wartość %2';
											|tr = 'Toplam tanım: %1, tutar %2'"), 
	                                     GoodsQuantity, 
	                                     SumFormat(AmountToBeRegistered, HeaderData_.Currency));
	TotalString = TotalString + StringOfTotalTitles;
	
	If HeaderData_.ConsiderVAT And HeaderData_.PriceIncludesVAT Then
		
		VATLine = StrTemplate(NStr("vi = 'gồm thuế GTGT %1 %2';
									|ru = 'в том числе НДС %1 %2';
									|en = 'including VAT %1 %2'; fa = 'including VAT %1 %2';
									|it = 'di cui IVA %1 %2';
									|pl = 'w tym VAT %1 %2';
									|tr = 'KDV dahil %1 %2'"), Format(AmountTotalVAT,"NFD=2; NDS=,; NZ=0,00"),CurrencyPresentation);
			TotalString = TotalString + ", " + VATLine;
		
	EndIf;
	
	If Not HeaderData_.ConsiderVAT Then
		
		TotalString = TotalString + ", " + NStr("vi = 'Không gồm thuế (GTGT)';
												|ru = 'Без налога (НДС)';
												|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
												|it = 'senza imposta (IVA)';
												|pl = 'bez podatku (VAT)';
												|tr = 'Vergisiz (KDV)'");
		
	EndIf;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("TotalString",TotalString);
	ReturnStructure.Insert("AmountInWords",AmountInWords);
	
	Return ReturnStructure;

EndFunction




#Region PreparationAndAnalysisOfElectronicDocuments

// Generates a match for the array of passed keys
//
// Parameters:
//  RowsArray     - Array    - contains the keys.
//  FieldsStructure  - Structure - contain the value.
//
// Returns:
//   Map   - formed match.
//
Function FieldValueConstructor(Val RowsArray,Val FieldsStructure) Export
	
	Response = New Map;
	
	For Each ArrayRow In RowsArray Do
		
		Response.Insert(ArrayRow, Common.CopyRecursive(FieldsStructure));
		
	EndDo;
	
	Return Response;
	
EndFunction

// Forms the structure of types used in electronic data documents.
// 
// Returns:
//  Structure - Description of types:
//   * Basic         - TypeDescription - any simple type: string, boolean, number, date.
//   * Boolean          - TypeDescription - the type is boolean.
//   * Number           - TypeDescription - type number.
//   * NumberQuantity - TypeDescription - type number: 17 digits, 3 decimal places.
//   * NumberSum      - TypeDescription - type number: 15 digits, 2 decimal places.
//   * NumberPercentage    - TypeDescription - number type: 5 digits, 2 decimal places.
//   * Date            - TypeDescription - type date.
//   * String          - TypeDescription - type string.
//   * Structure       - TypeDescription - type structure.
//   * Array          - TypeDescription - type array.
//   * ValueTable - TypeDescription - type table of values.
//
Function DataTypesOfElectronicDocuments() Export
	
	Result = New Structure;
	Result.Insert("Basic"        ,     New TypeDescription("String, Boolean, Number, Date"));
	Result.Insert("Boolean"         ,     New TypeDescription("Boolean"));
	Result.Insert("Number"          ,     New TypeDescription("Number"));
	Result.Insert("NumberQuantity",     New TypeDescription("Number",,,New NumberQualifiers(17,3)));
	Result.Insert("NumberSum"     ,     New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	Result.Insert("NumberPercentage"   ,     New TypeDescription("Number",,,New NumberQualifiers(5,2)));
	Result.Insert("Date"           ,     New TypeDescription("Date"));
	Result.Insert("String"         ,     New TypeDescription("String"));
	Result.Insert("Structure"      ,     New TypeDescription("Structure"));
	Result.Insert("Array"         ,     New TypeDescription("Array"));
	Result.Insert("Table"        ,     New TypeDescription("ValueTable"));
	
	Return Result;
	
EndFunction

// Creates a structure that describes the logistics packaging for an electronic document.
//
// Parameters:
//  UnitOfMeasure - DefinedType.PackageEDLItems - the unit of measurement for which the description is generated.
//  MeaningOfUnitsOfMeasurement - Map - contains the values of the fields required for generating the description.
//
// Returns:
//  Structure - contains fields:
//  * LongDesc    - String - description of the unit of measurement
//  * Numerator   - Number - numerator of the conversion factor.
//  * Denominator - Number - denominator of the conversion factor.
//
Function LogisticsPackagingForED(UnitOfMeasure, MeaningOfUnitsOfMeasurement) Export
	
	FieldsValues = MeaningOfUnitsOfMeasurement[UnitOfMeasure];
	Response         = New Structure("LongDesc, Numerator, Denominator");
	
	FillPropertyValues(Response, FieldsValues);
	Response.LongDesc = FieldsValues.LogisticsPackagingName;
	Return Response;
	
EndFunction

// Creates a structure that describes the product data for an electronic document.
//
// Parameters:
//  SampleProducts_                 - QueryResultSelection - contains data about the item, characteristic, and unit of measurement.
//  ValuesOfProductItemFields     - Map    - contains the values of the required item fields.
//  ValuesOfFeatureFields    - Map    - contains the values of the required characteristic fields.
//  ValueOfUnitFields - Map    - contains the values of the required unit of measurement fields.
//  TableWithBarcodes          - ValueTable - data bar code according to the nomenclature of the document.
//
// Returns:
//  Structure - Product data for Ed:
// * ProductsLink - DefinedType.EDLProducts
// * CharacteristicReference - DefinedType.ItemsCharacteristicEDL
// * UnitOfMeasureLink - DefinedType.PackageEDLItems 
// * NomenclatureName - String 
// * CharacteristicName - String 
// * UnitOfMeasurementCodeOceania - Number 
// * UnitOfMeasurementName - String
// * LongDesc - String
// * SupplierProductID - String
// * Manufacturer - Undefined
// * Barcodes - Array of String
// * ProductDetails__ - Undefined 
// * Products1CService - Undefined 
// * TradeMark - Undefined 
// * Image - String
Function ProductDataForEd(Val SampleProducts_, Val ValuesOfProductItemFields,
			Val ValuesOfFeatureFields, Val ValueOfUnitFields, Val TableWithBarcodes) Export
	
	Var_Key = New Structure;
	Var_Key.Insert("Products"    , SampleProducts_.Products);
	Var_Key.Insert("Characteristic"  , SampleProducts_.Characteristic);
	Var_Key.Insert("UnitOfMeasure", SampleProducts_.UnitOfMeasure);
	
	Response = New Structure();
	Response.Insert("ProductsLink"          , Undefined);
	Response.Insert("CharacteristicReference"        , Undefined);
	Response.Insert("UnitOfMeasureLink"      , Undefined);
	Response.Insert("NomenclatureName"    , "");
	Response.Insert("CharacteristicName"  , "");
	Response.Insert("UnitOfMeasurementCodeOceania"     , 0);
	Response.Insert("UnitOfMeasurementName", "");
	Response.Insert("LongDesc"                    , "");
	Response.Insert("SupplierProductID"           , "");
	Response.Insert("Manufacturer"               , Undefined);
	Response.Insert("Barcodes"                   , New Array);
	Response.Insert("ProductDetails__"             , Undefined);
	Response.Insert("Products1CService"        , Undefined);
	Response.Insert("TradeMark"               , Undefined);
	Response.Insert("Image"             	 , "");
	
	FillPropertyValues(Response, ValuesOfProductItemFields[SampleProducts_.Products]);
	FillPropertyValues(Response, ValuesOfFeatureFields[SampleProducts_.Characteristic]);
	FillPropertyValues(Response, ValueOfUnitFields[SampleProducts_.UnitOfMeasure]);
	
	RemoveSpacesFromCollectionStringValues(Response);
	
	Response.Barcodes = TableWithBarcodes.Copy(Var_Key, "Barcode").UnloadColumn("Barcode");
	
	Return Response;
	
EndFunction

// Creates a structure that describes the data of the organization or counterparty.
//
// Parameters:
//  Member        - DefinedType.Organization, DefinedType.EDLCounterparty - one of the sides of the commercial offer.
//
// Returns:
//  Structure - contains fields:
//   * Ref           - DefinedType.Organization, DefinedType.EDLCounterparty - a reference to a directory element.
//   * Description     - String - name of the counterparty or organization.
//   * LegalAddress - String - legal address of the counterparty or organization.
//   * Kind              - Structure - if it is an individual entrepreneur, then "INN, first Name, Last name, patronymic",
//                                     if it is a legal Entity, then "INN, KPP".
//
Function DataOfParticipantOfCommercialOffers(Val Member) Export
	
	ParticipantData = New Structure;
	If ValueIsFilled(Member) Then
		CommercialProposalsDocumentsOverridable.DataOfParticipantOfCommercialOffers(Member, ParticipantData);
	EndIf;
	
	Return ParticipantData;
	
EndFunction

// Returns a structure containing the necessary data about the user.
//
// Parameters:
//    Manager - CatalogRef.Users - owner of the contact information.
//    ManagerPresentation - String - Full name of the user.
//
// Returns:
//  Structure - manager data:
//    * LASTFIRSTNAME - String - Full name of the Manager.
//    * Email - String - email address.
//    * Phone - String - phone number.
//
Function DetailsOfManagerAsContactPerson(Manager, ManagerPresentation) Export
	
	ContactPersonDetails = New Structure;
	
	ContactPersonDetails.Insert("LASTFIRSTNAME", ManagerPresentation);
	
	ManagerContactInformation = ManagerContactInformation(Manager);
	ContactPersonDetails.Insert("Email", ManagerContactInformation.Email);
	ContactPersonDetails.Insert("Phone",          ManagerContactInformation.Phone);
	
	Return ContactPersonDetails;
	
EndFunction

// Creates a table with data from the owner's attached files.
//
// Parameters:
//  FilesOwner          - DocumentRef, CatalogRef - owner of the attached files.
//  HTMLAttachmentCID  - Boolean - indicates that you need files that contain the CID of the Htmlinjection.
//                 If there is no such field in the directory of attached files, then you need to pass it Undefined.
//
// Returns:
//   ValueTable - contains information about the owner's attached files:
//     * Ref - CatalogRef
//     * FileName - String
//     * Size - Number
//     * DeletionMark - Boolean
//     * FileExtention - String
//
Function TableOfAttachedFilesForED(FilesOwner, HTMLAttachmentCID = Undefined) Export
	
	SetPrivilegedMode(True);
	
	OwnerMetadata = Metadata.FindByType(TypeOf(FilesOwner));
	StandardMainCatalogName = OwnerMetadata.Name + "AttachedFiles";
	
	QueryText =
	"SELECT
	|	AttachedFiles.Ref          AS Ref,
	|	AttachedFiles.Description    AS FileName,
	|	AttachedFiles.Size          AS Size,
	|	AttachedFiles.DeletionMark AS DeletionMark,
	|	AttachedFiles.Extension      AS FileExtention
	|FROM
	|	&CatalogName AS AttachedFiles
	|WHERE
	|	AttachedFiles.FileOwner = &FilesOwner
	|	AND &HTMLAttachmentCIDCondition";
	QueryText = StrReplace(QueryText, "&CatalogName", "Catalog." + StandardMainCatalogName);
	
	If HTMLAttachmentCID = Undefined Then
		QueryText = StrReplace(QueryText, "&HTMLAttachmentCIDCondition", "TRUE");
	ElsIf HTMLAttachmentCID = True Then
		QueryText = StrReplace(QueryText, "&HTMLAttachmentCIDCondition", "AttachedFiles.CIDAttachHTML <> """"");
	Else
		QueryText = StrReplace(QueryText, "&HTMLAttachmentCIDCondition", "AttachedFiles.CIDAttachHTML = """"");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("FilesOwner", FilesOwner);
	
	Return Query.Execute().Unload();
	
EndFunction

// Marks all attached files of the owner for deletion.
//
// Parameters:
//  FilesOwner - DocumentRef, CatalogRef - owner of the attached files.
//
Procedure DeleteAttachedObjectFiles(FilesOwner) Export
	
	TableOfAttachedFiles = TableOfAttachedFilesForED(FilesOwner);
	
	For Each FileString_ In TableOfAttachedFiles Do
		
		If FileString_.DeletionMark Then
			Continue;
		EndIf;
		
		FileObject1 = FileString_.Ref.GetObject();
		FileObject1.SetDeletionMark(True);
		
	EndDo;
	
EndProcedure


// Returns a structure containing the required user contact information.
//
// Parameters:
//    Manager - CatalogRef.Users - owner of the contact information.
//
// Returns:
//  Structure - Manager Contact Information:
//    * Email - String - email address.
//    * EmailMeetsRequirements_ - Boolean - indicates that the email address does not meet
//        the requirements of RFC 5321, RFC 5322, as well as RFC 5335, RFC 5336, and RFC 3696.
//    * Phone - String - phone number.
//
Function ManagerContactInformation(Manager) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Email",                         "");
	ReturnStructure.Insert("EmailMeetsRequirements_", False);
	ReturnStructure.Insert("Phone",                       "");
	
	AccountingSettings = AccountingSettings();
	
	ObjectsArray = New Array;
	ObjectsArray.Add(Manager);
	
	ArrayOfKiTypes = New Array;
	ArrayOfKiTypes.Add(AccountingSettings.TypeOfContactInformationEmailManager);
	ArrayOfKiTypes.Add(AccountingSettings.TypeOfContactInformationManagerSPhoneNumber);
	
	ContactInformationTable1 = ContactsManager.ObjectsContactInformation(ObjectsArray,, ArrayOfKiTypes, CurrentSessionDate());
	
	For Each TableRow In ContactInformationTable1 Do
		
		If TableRow.Kind = AccountingSettings.TypeOfContactInformationEmailManager
			And IsBlankString(ReturnStructure.Email) Then
			
			ReturnStructure.Email = TableRow.Presentation;
			ReturnStructure.EmailMeetsRequirements_ = CommonClientServer.EmailAddressMeetsRequirements(TableRow.Presentation)
			
		EndIf;
		
		If TableRow.Kind = AccountingSettings.TypeOfContactInformationManagerSPhoneNumber
			And IsBlankString(ReturnStructure.Phone) Then
			
			ReturnStructure.Phone = TableRow.Presentation;
			
		EndIf;
		
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

#EndRegion

// The function gets the conversion factor from the current currency to the new currency.
//
// Parameters:
//  CurrentCurrency - CatalogRef.Currencies - The current document currency
//  NewCurrency - CatalogRef.Currencies - The new currency of the document
//  Date - Date - document date.
//
// Returns:
//  Number - Conversion factor to the new currency.
//
Function ConversionRateFromCurrencyToCurrency(CurrentCurrency, NewCurrency, Date) Export
	
	If CurrentCurrency <> NewCurrency Then
		CurExchangeRate = CurrencyRateOperations.GetCurrencyRate(CurrentCurrency, Date);
		NewCurrencyRate = CurrencyRateOperations.GetCurrencyRate(NewCurrency, Date);
		If NewCurrencyRate.Rate * CurExchangeRate.Repetition <> 0 Then
			ConversionFactor_ = (CurExchangeRate.Rate * NewCurrencyRate.Repetition) / (NewCurrencyRate.Rate * CurExchangeRate.Repetition);
		Else
			ConversionFactor_ = 0;
		EndIf;
	Else
		ConversionFactor_ = 1;
	EndIf;
	
	Return ConversionFactor_;
	
EndFunction

// Returns the default unit of measurement if the application solution provides one. Otherwise It is Uncertain
// 
// Returns:
// 	DefinedType.PackageEDLItems, Undefined - Default unit of measurement
Function DefaultUnitOfMeasurement() Export
	
	Result = Undefined;
	
	CommercialProposalsDocumentsOverridable.WhenDefiningDefaultUnitOfMeasurement(Result);
	
	Return Result;
	
EndFunction

#Region StorageOfFormDataSettings

// Loads the saved settings of the Form image panel.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form to upload the saved settings to.
Procedure LoadSavedSettingsOfFormSImagePanel(Form) Export
	
	#If Not ExternalConnection Then
		
	ObjectKey = StrTemplate("%1/FormSettings", Form.FormName);

	SettingsKey = "VisibilityOfImagePanel";
	UploadSetSavedFormElementSettings(
		Form, ObjectKey, SettingsKey, "GroupGoodsImage", "Visible", True);
	
	PropertyValue = True;
	SettingsKey = "TaggingImageButton";
	UploadSetSavedFormElementSettings(
		Form, ObjectKey, SettingsKey, "ImagePanel", "Check", PropertyValue);
		
	CommonClientServer.SetFormAttributeByPath(Form, "PanelIsDisplayed", PropertyValue);

	#EndIf
	
EndProcedure

// Saves Form image panel settings
// 
// Parameters:
//  FormName - String - Name of the Form whose image panel settings you want to save
//  PanelIsDisplayed - Boolean - The current value of the property required for installation
Procedure SaveSettingsOfFormSImagePanel(FormName, PanelIsDisplayed) Export

	ObjectKey = StrTemplate("%1/FormSettings", FormName);
	
	SettingsKey = "VisibilityOfImagePanel";
	SaveFormElementSettings(
		ObjectKey, SettingsKey, "GroupGoodsImage", "Visible", PanelIsDisplayed);
		
	SettingsKey = "TaggingImageButton";
	SaveFormElementSettings(
		ObjectKey, SettingsKey, "ImagePanel", "Check", PanelIsDisplayed);	

EndProcedure

#EndRegion

#EndRegion

#Region Private



#Region Other

Function SumFormat(Val Sum, Currency = Undefined, NZ = "", NGS = "")
	
	Sum = ?(Sum < 0, -Sum, Sum);
	FormatString = "ND=15;NFD=2"
					+ ?(Not ValueIsFilled(NZ), "", ";" + "NZ=" + NZ)
					+ ?(Not ValueIsFilled(NGS),"", ";" + "NGS=" + NGS);
	ResultingLine = TrimL(Format(Sum, FormatString));
	
	If ValueIsFilled(Currency) Then
		ResultingLine = ResultingLine + " " + TrimR(Currency);
	EndIf;
	
	Return ResultingLine;

EndFunction

Procedure RemoveSpacesFromCollectionStringValues(ValueCollection)
	
	For Each CollectionItem In ValueCollection Do
		If TypeOf(CollectionItem.Value) = Type("String") Then
			ValueCollection[CollectionItem.Key] = TrimAll(CollectionItem.Value);
		EndIf;
	EndDo;
	
EndProcedure

Procedure UploadSetSavedFormElementSettings(
		Form, ObjectKey, SettingsKey, TagName, PropertyName, PropertyValue)
	
	DefaultSettings = NewElementForFormElementPropertySettings(
		TagName, PropertyName, PropertyValue);

	FormElementSettings =
		Common.FormDataSettingsStorageLoad(ObjectKey, SettingsKey, DefaultSettings);	
	
	CommonClientServer.SetFormItemProperty(Form.Items, FormElementSettings.TagName,
		FormElementSettings.PropertyName, FormElementSettings.Value);	
	
	PropertyValue = FormElementSettings.Value;
	
EndProcedure

Procedure SaveFormElementSettings(ObjectKey, SettingsKey, TagName, PropertyName, PropertyValue)

	SettingValue = NewElementForFormElementPropertySettings(
		TagName, PropertyName, PropertyValue);

	CommonServerCall.FormDataSettingsStorageSave(
		ObjectKey, SettingsKey, SettingValue);
	
EndProcedure

// Constructor. A new element for Form element property settings.
// 
// Parameters:
//  TagName - String
//  PropertyName - String
//  Value - String
// 
// Returns:
//  Structure:
// * TagName - String
// * PropertyName - String 
// * Value - String 
Function NewElementForFormElementPropertySettings(TagName, PropertyName, Value)
	
	Result = New Structure;
	Result.Insert("TagName", TagName);
	Result.Insert("PropertyName", PropertyName);
	Result.Insert("Value", Value);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
