
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Object.Ref.IsEmpty() Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	CommercialProposalsDocumentsOverridable.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	ProcessAdditionalInformationToClient();
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	CommercialProposalsDocumentsOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	WriteParameters.Insert("QuestionAboutCalculatingDiscountsIsRequired", False);
	If Not WriteParameters.Property("AnswerToQuestionAboutCalculatingDiscountsIsReceived") Then
		WriteParameters.Insert("AnswerToQuestionAboutCalculatingDiscountsIsReceived", False);
	EndIf;
	
	CommercialProposalsDocumentsClientOverridable.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If Not WriteParameters.AnswerToQuestionAboutCalculatingDiscountsIsReceived
		And WriteParameters.QuestionAboutCalculatingDiscountsIsRequired Then
		
		Cancel = True;
		
		NotificationAfterClose = New CallbackDescription(
					"SuggestUserToCalculateDiscountsCompletion", 
					ThisObject,
					WriteParameters);
					
		CommercialProposalsDocumentsClientOverridable.SuggestUserToCalculateDiscounts(ThisObject, Cancel, NotificationAfterClose);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	HTMLDocumentPrepared = False;
	
	TableOfMatchingAttachmentNamesCID.Clear();
	
	AttachmentsStructure = New Structure;
	BuyerInformationFormattedDocument.GetHTML(CurrentObject.AdditionalInformationToCustomerHTML, AttachmentsStructure);
	
	For Each Attachment In AttachmentsStructure Do
		
		NewRow = TableOfMatchingAttachmentNamesCID.Add();
		NewRow.FileName = Attachment.Key;
		NewRow.CID      = New UUID;
		NewRow.Picture = Attachment.Value;
		
	EndDo;
	
	If TableOfMatchingAttachmentNamesCID.Count() > 0 Then
		
		HTMLDocument = CommercialProposalsDocuments.HTMLDocumentObjectFromHTMLText(CurrentObject.AdditionalInformationToCustomerHTML);
		CommercialProposalsDocuments.ReplaceImageNamesWithHTMLAttachmentCIDs(HTMLDocument, TableOfMatchingAttachmentNamesCID.Unload());
		
		HTMLDocumentPrepared = True;
		
	EndIf;
	
	If HTMLDocumentPrepared Then
		
		CurrentObject.AdditionalInformationToCustomerHTML = CommercialProposalsDocuments.HTMLTextFromHTMLDocumentObject(HTMLDocument);
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SetPrivilegedMode(True);
	MailMessage = CurrentObject.Ref;
	
	FormattedDocumentPicturesAttachmentsTable = Documents.CommercialProposalForCustomer.AttachedFilesWithNonEmptyCID(Object.Ref);
	For Each Attachment In FormattedDocumentPicturesAttachmentsTable Do
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("Catalog.CommercialProposalForCustomerAttachedFiles");
		DataLockItem.SetValue("Ref", Attachment.Ref);
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		ObjectAttachment = Attachment.Ref.GetObject();
		ObjectAttachment.Delete();
		
	EndDo;
	
	For Each Attachment In TableOfMatchingAttachmentNamesCID Do
		
		BinaryPictureData = Attachment.Picture.GetBinaryData();
		PictureAddressInTempStorage = PutToTempStorage(BinaryPictureData, UUID);
		AttachedFile = CommercialProposalsDocuments.RecordAttachmentFromTemporaryStorage(
		                     MailMessage,
		                     PictureAddressInTempStorage,
		                     "_" + StrReplace(Attachment.CID, "-", "_"));
		
		If AttachedFile <> Undefined Then
			AttachedFileObject = AttachedFile.GetObject();
			AttachedFileObject.CIDAttachHTML = Attachment.CID;
			AttachedFileObject.Write();
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	FillInDependentDetailsOfTablePart();
	DetermineAvailabilityOfAdditionalInformation(ThisObject);
	AvailabilityControl(ThisObject);
	CalculateFormTotals(ThisObject);
	
	
	CommercialProposalsDocumentsOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	CommercialProposalsDocumentsClientOverridable.OnOpen(ThisObject, Cancel);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	CommercialProposalsDocumentsClientOverridable.OnClose(ThisObject, Exit);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	CommercialProposalsDocumentsClientOverridable.SelectionProcessingProductSelection(
		ThisObject,
		New CallbackDescription("Attachable_ProcessingProductSelectionResults", ThisObject),
		ValueSelected, 
		ChoiceSource);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	CommercialProposalsDocumentsClientOverridable.ProcessingAndSelectionOfProducts(
			ThisObject,
			New CallbackDescription("Attachable_ProcessingProductSelectionResults", ThisObject),
			EventName,
			Parameter,
			Source);
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	
	If EventName = "Write_File" Then
		
		FormCaptionAttachedFiles();
		
	EndIf;
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"
		And Parameter.Find(Object.Ref) <> Undefined Then
		Read();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ExternalEvent(Source, Event, Data)
	
	CommercialProposalsDocumentsClientOverridable.ExternalEvent(ThisObject, Source, Event, Data);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("CommercialOfferToClient__", Object.DocumentBasis, Object.Ref);
	Notify("ChangedStatusOfRequestForCommercialProposals", "ThereIsResponseToRequest", Object.SKPIDInService);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FormPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BuyerInformationFormattedDocumentOnChange(Item)
	
	DetermineAvailabilityOfAdditionalInformation(ThisObject);
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenDocument_" Then
		
		If ValueIsFilled(Object.DocumentBasis) Then
			ShowValue(, Object.DocumentBasis);
		EndIf;
		
	ElsIf FormattedStringURL = "OpenQueryDocument" Then
		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TaxationOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingVATTaxation(ThisObject, ServerCallRequired__);
	If ServerCallRequired__ Then
		TaxationOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.OnChangePriceIncludesVAT(ThisObject, Object.Taxation, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		PriceIncludesVATOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ClientOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingPartner(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		ClientOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingCounterparty(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		CounterpartyOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingCurrency(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ 
		Or OnRequest Then
		CurrencyOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If OnRequest Then 
		DateOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidityPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingValidityPeriodOfCommercialOffer(ThisObject, 
	                                                                                                         CommonClient.SessionDate(),
	                                                                                                         ServerCallRequired__);
	
	If ServerCallRequired__ Then
		ValidityPeriodOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure OperationOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenBusinessTransactionChanges(ThisObject, ServerCallRequired__);
	If ServerCallRequired__ Then
		OperationOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure NotPartialSaleAllowedOnChange(Item)
	
	ServerCallRequired__ = False;
	
	Object.PartialSaleAllowed = Not NotPartialSaleAllowed;
	CommercialProposalsDocumentsClientOverridable.WhenChangingFlagCanBeRedeemedPartially(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		NotPartialSaleAllowedOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenStatusChanges(ThisObject, CommonClient.SessionDate(), ServerCallRequired__);
	
	If ServerCallRequired__ Then
		StatusOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingManager(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		ManagerOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingContactPerson(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		ContactPersonOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenOrganizationChanges(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		OrganizationOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure OptionToSpecifyDeliveryTermOnChange(Item)
	
	CommercialProposalsDocumentsClientServer.ColumnManagementDeliveryTime(Object.OptionToSpecifyDeliveryTerm,
	                                                                            Items.GoodsDeliveryPeriodDays,
	                                                                            Items.SpecifyDeliveryTerm);
	CommercialProposalsDocumentsClientServer.ClearDeliveryTimeIfDoesNotMatchOption(Object.Goods, "DeliveryPeriodDays", Object.OptionToSpecifyDeliveryTerm);
	
EndProcedure

&AtClient
Procedure DecorationEDOStateClick(Item)
	
	
EndProcedure

&AtClient
Procedure OpenAttachedFilesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "Open" Then
		
		StandardProcessing = False;
		CommercialProposalsDocumentsClient.OpenListOfAttachedFiles(ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Goods.CurrentData;
		
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If OnRequest Then
		
		Cancel = True;
		
		If CurrentData.OfferNumberForTheRequestLine = 1 Then
			DeleteLinesWithSuggestionsForQueryString(CurrentData.RowIDRequest);
		Else
			DeleteQueryString(CurrentData);
		EndIf;
		
	EndIf;
	
	CommercialProposalsDocumentsClientOverridable.GoodsBeforeDeleteRow(ThisObject,
	                                                                            Item, 
	                                                                            CurrentData, 
	                                                                            Cancel);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingProducts(ThisObject, 
	                                                                                CurrentData, 
	                                                                                "Products", 
	                                                                                ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsProductsOnChangeServer();
	EndIf;
	
	UpdateInformationRequestedRequestedIfRequested(CurrentData);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingCharacteristics(ThisObject,
	                                                                                  CurrentData, 
	                                                                                  Item,
	                                                                                  ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsCharacteristicOnChangeServer();
	EndIf;
	
	UpdateInformationRequestedRequestedIfRequested(CurrentData);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsUnitOfMeasureOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingUnitOfMeasurement(ThisObject, 
	                                                                                    CurrentData, 
	                                                                                    ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsUnitOfMeasureOnChangeServer();
	EndIf;
	
	UpdateInformationRequestedRequestedIfRequested(CurrentData);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingQuantity(ThisObject, CurrentData, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsCountOnChangeServer();
	EndIf;
	
	UpdateInformationRequestedRequestedIfRequested(CurrentData);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If OnRequest Then
		
		Cancel = True;
		
		AddLineByQueryPosition();
		
	EndIf;
	
EndProcedure

#Region PricesAmounts

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenPriceChanges(ThisObject, CurrentData, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsPriceOnChangeServer();
	EndIf;
	
	UpdateInformationRequestedRequestedIfRequested(CurrentData);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingPriceType(ThisObject, CurrentData, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsPriceKindOnChangeServer();
	EndIf;
	
	UpdateInformationRequestedRequestedIfRequested(CurrentData);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingAmount(ThisObject, CurrentData, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsSumOnChangeServer();
	EndIf;
	
	UpdateInformationRequestedRequestedIfRequested(CurrentData);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingVATRate(ThisObject, CurrentData, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsVATRateOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingVATAmount(ThisObject, CurrentData,
	                                                                            Object.PriceIncludesVAT, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		ProductsVATAmountWhenChangingServerChanges();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	AttachIdleHandler("WhenActivatingRowOfGoodsTable", 0.2, True);
	
EndProcedure

#EndRegion

#Region ManualDiscounts

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingPercentageOfManualDiscount(
	        ThisObject,
	        CurrentData,
	        Object.PriceIncludesVAT,
	        Object.Taxation,
	        ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsPercentRateOfManualDiscountOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenChangingAmountOfManualDiscount(
	         ThisObject,
	         CurrentData,
	         Object.PriceIncludesVAT,
	         Object.Taxation,
	         ServerCallRequired__);
	
	If ServerCallRequired__ Then
		GoodsManualDiscountOnChangeServer();
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

#EndRegion

#Region Comments

&AtClient
Procedure GoodsCommentForCustomerStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommentForBuyerBeginningOfChoice();
	
EndProcedure

&AtClient
Procedure GoodsInternalCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommentInternalStartOfSelection();
	
EndProcedure

&AtClient
Procedure TheCommoditiesReviewForTheBuyerSBasementStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommentForBuyerBeginningOfChoice();
	
EndProcedure

&AtClient
Procedure ProductsCommentInternalBasementStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommentInternalStartOfSelection();
	
EndProcedure

&AtClient
Procedure TheCommoditiesReviewForTheBuyerSBasementOnChange(Item)
	
	CommentInLineWhenChanging();
	
EndProcedure

&AtClient
Procedure ProductsCommentInternalBasementOnChange(Item)
	
	CommentInLineWhenChanging();
	
EndProcedure

&AtClient
Procedure GoodsInternalCommentOnChange(Item)
	
	CommentInLineWhenChanging();
	
EndProcedure

&AtClient
Procedure GoodsCommentForCustomerOnChange(Item)
	
	CommentInLineWhenChanging();
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ServerCallRequired__ = False;
	CommercialProposalsDocumentsClientOverridable.TabularPartSelection(ThisObject, Item, RowSelected, Field, StandardProcessing, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		ProcessingResult = Undefined;
		GoodsSelectionServer(Field.Name, ProcessingResult);
		CommercialProposalsDocumentsClientOverridable.AfterCompletingGoodsSelection(
			ThisObject, Field.Name, ProcessingResult);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInDeliveryTerms(Command)
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingCommandFillInDeliveryTerms(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPaymentTerms(Command)
	
	 CommercialProposalsDocumentsClientOverridable.WhenExecutingCommandFillInPaymentTerms(ThisObject);
	
 EndProcedure

#Region FillingInTablePartGoods

&AtClient
Procedure OpenSelection(Command)
	
	CommercialProposalsDocumentsClientOverridable.OpenProductSelectionForm_(ThisObject);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	NotificationOnCompletion = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	
	CommercialProposalsDocumentsClientOverridable.OpenUploadFormFromExternalFiles(ThisObject, NotificationOnCompletion);
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	
	CommercialProposalsDocumentsClientOverridable.ShowBarcodeInput(
		New CallbackDescription("SearchByBarcodeCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("SplitRowCompletion", ThisObject);
	CommercialProposalsDocumentsClientOverridable.WhenExecutingSplitLineCommand(ThisObject, CurrentData, CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	CallbackOnCompletion = New CallbackDescription("DownloadFromTSDCompletion", ThisObject);
	
	CommercialProposalsDocumentsClientOverridable.StartLoadingDataFromTSD(ThisObject, CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure NeedsFromQuery(Command)
	
	
EndProcedure

&AtClient
Procedure AddTheOfferForPosition(Command)

	AddLineByQueryPosition();
	
EndProcedure

&AtClient
Procedure SpecifyDeliveryTerm(Command)
	
	If Object.OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedInDaysSinceMomentOfOrder") Then
		
		Notification = New CallbackDescription("DeliveryPeriodDaysCompletion", ThisObject, True);
		
		ShowInputNumber(Notification,
			1,
			NStr("vi = 'Nhập thời gian giao hàng';
				|ru = 'Введите срок поставки';
				|en = 'Enter the delivery period'; fa = 'Enter the delivery period';
				|it = 'Inserire i tempi di consegna';
				|pl = 'Wprowadź termin dostawy';
				|tr = 'Teslimat süresi girin'"),
			3,
			0);
		
	ElsIf Object.OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedAtSpecificDate") Then
		
		Notification = New CallbackDescription("DeliveryPeriodDaysCompletion", ThisObject, False);
		
		ShowInputDate(Notification,
			?(ValueIsFilled(Object.ValidityPeriod), Object.ValidityPeriod, Object.Date),
			NStr("vi = 'Nhập ngày giao hàng';
				|ru = 'Введите дату поставки';
				|en = 'Enter delivery date'; fa = 'Enter delivery date';
				|it = 'Inserire la data di consegna';
				|pl = 'Wprowadź datę dostawy';
				|tr = 'Teslimat tarihi girin'"),
			DateFractions.Date);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HoldAndCloseTheDocument(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Document.CommercialProposalForCustomer.Form.DocumentForm.PostAndClose");
	
	ClearMessages();
	WriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
	
	If Write(WriteParameters) Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Document.CommercialProposalForCustomer.Form.DocumentForm.Write");
	
	ClearMessages();
	Write();
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Document.CommercialProposalForCustomer.Form.DocumentForm.Post");
	
	ClearMessages();
	WriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
	Write(WriteParameters);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If OnRequest Then
		Return;
	EndIf;
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CopyLinesOnServer();
	ShowUserNotification(NStr("vi = 'Sao chép vào bộ đệm trao đổi';
								|ru = 'Копирование в буфер обмена';
								|en = 'Copy to clipboard'; fa = 'کپی در کلیپ‌بورد';
								|it = 'Copia negli appunti';
								|pl = 'Kopiowanie do schowka';
								|tr = 'Panoya kopyala'"), Window.GetURL(), 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã sao chép dòng: %1';
																		|ru = 'Скопировано строк: %1';
																		|en = 'Lines copied: %1'; fa = 'Lines copied: %1';
																		|it = 'Copiate righe: %1';
																		|pl = 'Skopiowano wierszy: %1';
																		|tr = 'Kopyalanmış satırlar: %1'"), Items.Goods.SelectedRows.Count()));
	Notify("DataCopiedToClipboard", New Structure("CopySource", "Goods"), Object.Ref);
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	If OnRequest Then
		Return;
	EndIf;
	
	Count = ResultOfInsertingRows();
	If Count > 0 Then
		ShowUserNotification(NStr("vi = 'Chèn từ bộ đệm trung gian';
									|ru = 'Вставка из буфера обмена';
									|en = 'Paste'; fa = 'Paste';
									|it = 'Immissione dal buffer di scambio';
									|pl = 'Wstaw ze schowka';
									|tr = 'Panodan kopyalama'"), Window.GetURL(), 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chèn dòng: %1';
																			|ru = 'Вставлено строк: %1';
																			|en = 'Inserted lines: %1'; fa = 'Inserted lines: %1';
																			|it = 'Inserite righe: %1';
																			|pl = 'Wstawiono wierszy: %1';
																			|tr = 'Eklenmiş satırlar: %1'"), Count));
	EndIf;
	
EndProcedure

#EndRegion

#Region PricesAndDiscounts

&AtClient
Procedure FillInPricesBySalesConditions(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", Items.Goods.SelectedRows);
	NotificationAfterSelectingSalesCondition = New CallbackDescription("AfterSelectingSalesCondition", ThisObject, AdditionalParameters);
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingCommandFillInPricesAccordingToTermsOfSale(ThisObject, NotificationAfterSelectingSalesCondition);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", Items.Goods.SelectedRows);
	NotificationAfterSelectingPriceType = New CallbackDescription("AfterSelectingTypeOfPrice", ThisObject, AdditionalParameters);
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingCommandFillInPricesByPriceType(ThisObject, NotificationAfterSelectingPriceType);
	
EndProcedure

&AtClient
Procedure CalculateDiscounts(Command)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingCalculateDiscountsCommand(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		Result = Undefined;
		CalculateDiscountsOnServer(Result);
		CommercialProposalsDocumentsClientOverridable.AfterCalculatingDiscounts(ThisObject, Result);
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure AssignAutomaticDiscounts(Command)
	
	ServerCallRequired__ = False;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", Items.Goods.SelectedRows);
	NotificationAfterAssigningAutomaticDiscount = New CallbackDescription("AfterAssigningAutomaticDiscount", ThisObject, AdditionalParameters);
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingAssignAutomaticDiscountsCommand(
		ThisObject, NotificationAfterAssigningAutomaticDiscount, ServerCallRequired__);
		
	If ServerCallRequired__ Then
		Result = Undefined;
		WhenAssigningAutomaticDiscountsOnServer(Result);
		CommercialProposalsDocumentsClientOverridable.AfterPreparingAppointmentOfAutomaticDiscounts(
			ThisObject, NotificationAfterAssigningAutomaticDiscount, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAManualDiscount(Command)
	
	StandardProcessing = True;
	ServerCallRequired__ = False;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", Items.Goods.SelectedRows);
	
	NotificationAfterAssigningManualDiscount = New CallbackDescription("AfterAssigningManualDiscount", ThisObject, AdditionalParameters);
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingAssignManualDiscountCommand(
		ThisObject, Items.Goods.SelectedRows, StandardProcessing, ServerCallRequired__);
	
	If StandardProcessing Then
		
		ShowInputNumber(NotificationAfterAssigningManualDiscount, 0, NStr("vi = 'Nhập phần trăm chiết khấu';
																			|ru = 'Укажите процент скидки';
																			|en = 'Specify discount percentage'; fa = 'Specify discount percentage';
																			|it = 'Specificare la percentuale dello sconto';
																			|pl = 'Podaj procent rabatu';
																			|tr = 'İndirim yüzdesini belirtin'"), 4, 2);
		
	ElsIf ServerCallRequired__ Then
		
		ProcessingResult = Undefined;
		WhenAssigningManualDiscountOnServer(ProcessingResult);
		CommercialProposalsDocumentsClientOverridable.AfterPreparingAssignmentOfManualDiscounts(
		        ThisObject,
		        Items.Goods.SelectedRows,
		        NotificationAfterAssigningManualDiscount,
		        ProcessingResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAssigningManualDiscount(Result, AdditionalParameters) Export

	If Result <> Undefined Then
		
		If AdditionalParameters.Property("StandardProcessing") 
			And Not AdditionalParameters.StandardProcessing Then
			
			If AdditionalParameters.Property("ServerCallRequired__")
				And AdditionalParameters.ServerCallRequired__ Then
				
				AfterAssigningManualDiscountOnServer(Result, Items.Goods.SelectedRows, AdditionalParameters);
				
			EndIf;
			
		Else
		
			For Each SelectedRow In AdditionalParameters.SelectedRows Do
				RowData = Items.Goods.RowData(SelectedRow);
				RowData.PercentRateOfManualDiscount = Result;
				CommercialProposalsDocumentsClientOverridable.WhenChangingPercentageOfManualDiscount(
				        ThisObject,
				        RowData,
				        Object.PriceIncludesVAT,
				        Object.Taxation);
			EndDo;
			
		EndIf;
		
		CalculateFormTotals(ThisObject);
		CommercialProposalsDocumentsClientOverridable.AfterCompletingAssignmentOfManualDiscounts(ThisObject, Items.Goods.SelectedRows, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAssigningAutomaticDiscount(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ServerCallRequired__ = False;
		
		CommercialProposalsDocumentsClientOverridable.AfterAssigningAutomaticDiscount(
			ThisObject, Result, ServerCallRequired__);
			
		If ServerCallRequired__ Then
			AfterAssigningAutomaticDiscountOnServer(Result, AdditionalParameters);
			CommercialProposalsDocumentsClientOverridable.AfterCalculatingAssignedAutomaticDiscounts(
				ThisObject, Result);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingCancelManualDiscountsCommand(
	           ThisObject, 
	           Items.Goods.SelectedRows, 
	           Object.PriceIncludesVAT, 
	           Object.Taxation,
	           ServerCallRequired__);
	
	If ServerCallRequired__ Then
		Result = Undefined;
		WhenCancelingManualDiscountsOnServer(Result);
		CommercialProposalsDocumentsClientOverridable.AfterCancelingManualDiscounts(
		        ThisObject,
		        Items.Goods.SelectedRows,
		        Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscounts(Command)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingOpenDiscountInformationCommand(ThisObject, ServerCallRequired__);
	
	If ServerCallRequired__ Then
		Result = Undefined;
		PrepareOpeningInformationAboutDiscountsOnServer(Result);
		CommercialProposalsDocumentsClientOverridable.AfterPreparingOpeningOfInformationAboutDiscounts(ThisObject, Result);
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
EndProcedure

// Parameters:
// 	Command - FormCommand
&AtClient
Procedure Attachable_OverriddenCommand(Command)
	
	ServerCallRequired__ = False;
	
	CommercialProposalsDocumentsClientOverridable.WhenExecutingOverridableCommand(
		ThisObject, Command, ServerCallRequired__);
		
	If ServerCallRequired__ Then
		Result = Undefined;
		OverridableServerCommand(Command.Name, Result);
		CommercialProposalsDocumentsClientOverridable.AfterExecutingRedefinedCommand(
			ThisObject, Command, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	CommercialProposalsDocumentsClientOverridable.ExecutePlugInIntegrationCommand(Command, ThisForm, Object);
	
EndProcedure

#EndRegion

#Region IntroductionOfBSPSubsystems

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties
#EndRegion


#EndRegion

#Region Private

#Region FormItemsManagement

&AtServer
Procedure CustomizeFormElements()
	
	Items.GroupBaseDocumentPresentation.Visible       = OnRequest;
	Items.GoodsGroupRequestedLineNumberQuantity.Visible  = OnRequest;
	Items.GoodsCustomerProductsPresentation.Visible   = OnRequest;
	Items.GoodsGroupRequestedQuantity.Visible             = OnRequest;
	Items.ProductsInquiryPrice.Visible                            = OnRequest;
	Items.GroupInformationRequestedForTheProposedLine.Visible = OnRequest;
	Items.SelectProductsFromRequest.Visible                    = OnRequest;
	Items.ProductsAddOfferByItem.Visible          = OnRequest;
	Items.GoodsCopyRows.Visible                     = Not OnRequest;
	Items.GoodsInsertRows.Visible                        = Not OnRequest;
	
	Items.GoodsAdd.Visible                              = Not OnRequest;
	Items.GoodsSearchByBarcode.Visible                      = Not OnRequest And AccountingSettings.ImplementedBarcodeSearch;
	Items.GoodsSplitRow.Visible                         = AccountingSettings.ImplementedStringSplitting;
	Items.GoodsImportDataFromPDT.Visible                  = AccountingSettings.ImplementedLoadingTSDData;
	Items.GoodsOpenSelection.Visible            = Not OnRequest 
	                                                    And AccountingSettings.ImplementedSelectionOfProducts;
	Items.GoodsImportFromExternalFile.Visible = Not OnRequest 
	                                                    And AccountingSettings.ImplementedFillingInDocumentsFromExternalFile;
	
	Items.Organization.Visible = Not AccountingSettings.SingleOrganizationIsUsed;
	Items.Currency.Visible      = Not AccountingSettings.SingleCurrencyIsUsed;
	
	Items.Client.Visible         = AccountingSettings.PartnersAreUsed;
	Items.Counterparty.Visible     =  CommercialProposalsDocumentsClientServer.CounterpartyFieldVisible(AccountingSettings);

	Items.GoodsCharacteristic.Visible = AccountingSettings.ProductCharacteristicsAreUsed;
	
	Items.GoodsPercentRateOfAutomaticDiscountMarkup.Visible   = AccountingSettings.AutomaticDiscountsInSalesAreUsed;
	Items.GoodsDiscountMarkupAmount.Visible     = AccountingSettings.AutomaticDiscountsInSalesAreUsed;
	Items.ProductsCalculateDiscounts.Visible              = AccountingSettings.AutomaticDiscountsInSalesAreUsed;
	Items.GoodsAssignAutomaticDiscounts.Visible = AccountingSettings.AutomaticDiscountsInSalesAreUsed
	                                                         And AccountingSettings.AssignableAutomaticDiscountsInSalesAreUsed;

	Items.GoodsPercentRateOfManualDiscount.Visible   = AccountingSettings.ManualDiscountsAreUsedInSales;
	Items.GoodsManualDiscount.Visible     = AccountingSettings.ManualDiscountsAreUsedInSales;
	Items.GoodsAssignAManualDiscount.Visible = AccountingSettings.ManualDiscountsAreUsedInSales;
	Items.GoodsCancelManualDiscounts.Visible  = AccountingSettings.ManualDiscountsAreUsedInSales;
	
	Items.GoodsOpenInformationAboutDiscounts.Visible = (AccountingSettings.ManualDiscountsAreUsedInSales
	                                                      Or AccountingSettings.AutomaticDiscountsInSalesAreUsed)
	                                                      And AccountingSettings.ImplementedFormForViewingDiscounts;
	
	Items.ProductsAndPricesAccordingToTermsOfSale.Visible = AccountingSettings.ImplementedFillingInPricesAccordingToSalesConditions;
	Items.GoodsFillInPricesByPriceKind.Visible        = AccountingSettings.TypesOfPricesAreUsed 
	                                                         And AccountingSettings.ImplementedFillingPricesByTypeOfPrices;
	Items.GoodsPriceKind.Visible                       = AccountingSettings.TypesOfPricesAreUsed;
	
	ThereAreDiscounts        = AccountingSettings.ManualDiscountsAreUsedInSales Or AccountingSettings.AutomaticDiscountsInSalesAreUsed;
	ThereIsFillingOfPrices = AccountingSettings.ImplementedFillingInPricesAccordingToSalesConditions Or AccountingSettings.ImplementedFillingPricesByTypeOfPrices;
	
	If ThereAreDiscounts And Not ThereIsFillingOfPrices Then
		Items.GroupPricesDiscounts.Title = NStr("vi = 'Chiết khấu';
												|ru = 'Скидки';
												|en = 'Discounts'; fa = 'تخفیف‌ها';
												|it = 'Sconti';
												|pl = 'Discounts';
												|tr = 'İndirimler'");
	ElsIf ThereIsFillingOfPrices And Not ThereAreDiscounts Then
		Items.GroupPricesDiscounts.Title = NStr("vi = 'Đơn giá';
												|ru = 'Цены';
												|en = 'Prices'; fa = 'قیمت‌ها';
												|it = 'Prezzi';
												|pl = 'Prices';
												|tr = 'Fiyatlar'");
	EndIf;
	
	Items.FillInPaymentTerms.Visible   = AccountingSettings.ImplementedFillingInPaymentTerms;
	Items.FillInDeliveryTerms.Visible = AccountingSettings.ImplementedFillingInDeliveryTerms;
	
	Items.EmptyDecorationOtherTermsOfDelivery.Visible = AccountingSettings.ImplementedFillingInPaymentTerms
	                                                          And AccountingSettings.ImplementedFillingInDeliveryTerms;
	
	Items.GoodsQueryDeliveryPeriodPresentation.Visible = OnRequest And AtLeastOneDeliveryPeriodIsSpecified;
	
	CommercialProposalsDocumentsClientServer.ColumnManagementDeliveryTime(Object.OptionToSpecifyDeliveryTerm, Items.GoodsDeliveryPeriodDays, Items.SpecifyDeliveryTerm);
	CommercialProposalsDocumentsClientServer.ClearDeliveryTimeIfDoesNotMatchOption(Object.Goods, "DeliveryPeriodDays", Object.OptionToSpecifyDeliveryTerm);
	
	FormPresentationOfFoundationDocument();
	
	If AccountingSettings.StatusOfCommercialOffersToClientsIsUsed Then
		CommercialProposalsDocumentsClientServerOverridable.GenerateStatePresentationByStatus(ThisObject, Object.Status, CurrentSessionDate());
	EndIf;
	
	Items.Goods.ChangeRowOrder = Not OnRequest;
	CommonClientServer.SetFormItemProperty(Items, "ProductsMove", "Visible", Not OnRequest);
	CommonClientServer.SetFormItemProperty(Items, "ProductsMove1", "Visible", Not OnRequest);
	CommonClientServer.SetFormItemProperty(Items, "ProductsContextMenuMove", "Visible", Not OnRequest);
	CommonClientServer.SetFormItemProperty(Items, "ProductsSorting", "Visible", Not OnRequest);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	Form.Items.OpenAttachedFiles.Enabled = Not Form.Object.Ref.IsEmpty();
	
EndProcedure

#EndRegion

#Region IntroductionOfBSPSubsystems

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Comments

&AtClient
Procedure CommentInternalStartOfSelection()

	CommercialProposalsDocumentsClient.CommentStartChoice(ThisObject,
	                                                               "InternalComment",
	                                                                "HasComment",
	                                                                "ProductsCommentInternalBasement",
	                                                                "CommentForCustomer");

EndProcedure

&AtClient
Procedure CommentForBuyerBeginningOfChoice()

	CommercialProposalsDocumentsClient.CommentStartChoice(ThisObject,
	                                                               "CommentForCustomer",
	                                                               "HasComment",
	                                                               "TheCommoditiesReviewForTheBuyerSBasement",
	                                                               "InternalComment");

EndProcedure

&AtClient
Procedure CommentInLineWhenChanging()
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsClient.DetectPresenceOfCommentInLine(CurrentData, 
	                                                                           "InternalComment", 
	                                                                           "CommentForCustomer", 
	                                                                            "HasComment"); 
	
EndProcedure

#EndRegion

#Region AdditionalInformationToClient

&AtServer
Procedure ProcessAdditionalInformationToClient()

	If Not Object.Ref.IsEmpty() 
		And ValueIsFilled(Object.AdditionalInformationToCustomerHTML) Then
		
		CIDAttachmentTable = Documents.CommercialProposalForCustomer.AttachedFilesWithNonEmptyCID(Object.Ref);
		AttachmentsWithANonEmptyCID.LoadValues(CIDAttachmentTable.UnloadColumn("Ref"));
		
		AttachmentsStructure = New Structure;
		Object.AdditionalInformationToCustomerHTML = CommercialProposalsDocuments.ProcessedHTMLTextForFormattedDocument(
		                                             Object.Ref, Object.AdditionalInformationToCustomerHTML, AttachmentsStructure);
		BuyerInformationFormattedDocument.SetHTML(Object.AdditionalInformationToCustomerHTML, AttachmentsStructure);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure DetermineAvailabilityOfAdditionalInformation(Form)
	
	TextAdditionalInformation = Form.BuyerInformationFormattedDocument.GetText();
	
	Form.Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(TextAdditionalInformation);
	
EndProcedure

#EndRegion

#Region AddingRowsFromQuery

&AtClient
Procedure AddCompletionFromRequest(Result, AdditionalParameters) Export 
	
	If Result = Undefined Then 
		Return;
	EndIf;
	
	AddRowsFromQuery(Result);
	
EndProcedure


&AtServer
Procedure AddRowsFromQuery(ArrayOfIDsOfQueryStringsToAdd)


EndProcedure

#EndRegion

#Region LoadingFromExternalFile

&AtClient
Procedure ImportFromExternalFileCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	LoadDataReceivedFromExternalFile(Result);

EndProcedure 

&AtServer
Procedure LoadDataReceivedFromExternalFile(Result)

	CommercialProposalsDocumentsOverridable.LoadDataReceivedFromExternalFile(ThisObject, Result);
	CalculateFormTotals(ThisObject);

EndProcedure

#EndRegion

#Region InformationRequestedOffered

&AtClient
Procedure WhenActivatingRowOfGoodsTable()
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		InformationRequestedOfferedOnString = Undefined;
		Return;
	EndIf;
	
	UpdateInformationRequestedRequestedIfRequested(CurrentData);
	
EndProcedure

&AtServer
Procedure GenerateInformationRequestedSuggestedByLine(RowID)

	CurrentData = Object.Goods.FindByID(RowID);
	InformationRequestedOfferedOnString.Clear();
	
	TemplateRequested = Documents.CommercialProposalForCustomer.GetTemplate("ComparisonRequestedOffered");
	Header = TemplateRequested.GetArea("Header");
	
	If CurrentData.OfferNumberForTheRequestLine = 1 Then
		
		QueryStringData = CurrentData;
		
	Else
		
		SearchParameters = New Structure;
		SearchParameters.Insert("RowIDRequest",      CurrentData.RowIDRequest);
		SearchParameters.Insert("OfferNumberForTheRequestLine", 1);
		
		FoundRows = Object.Goods.FindRows(SearchParameters);
		If FoundRows.Count() > 0 Then
			QueryStringData = FoundRows[0];
		Else
			Return;
		EndIf;
		
	EndIf;
	
	Header.Parameters.QueryQuantity       = QueryStringData.QueryQuantity;
	Header.Parameters.QueryUnitOfMeasure = QueryStringData.QueryUnitOfMeasure;
	Header.Parameters.QueryPrice             = QueryStringData.RequestPriceDocumentCurrency;
	Header.Parameters.LineNumber            = CurrentData.LineNumber;
	Header.Parameters.Products           = CurrentData.Products;
	Header.Parameters.Count             = CurrentData.Count;
	Header.Parameters.UnitOfMeasure       = CurrentData.UnitOfMeasure;
	Header.Parameters.Price                   = CurrentData.Price;
	Header.Parameters.Currency                 = Object.Currency;
	
	CommercialProposalsDocumentsOverridable.WhenFillingInComparisonParametersItIsRequestedThat(Header.Parameters, QueryStringData, CurrentData);
	
	RowsArray = New Array;
	RowsArray.Add(Format(QueryStringData.QueryLineNumber, "NG="));
	RowsArray.Add(". ");
	RowsArray.Add(QueryStringData.CustomerProductsPresentation);
	
	Header.Parameters.ProductsRequested = StrConcat(RowsArray);
	
		If CurrentData.Price > QueryStringData.QueryPrice 
		And QueryStringData.QueryPrice <> 0 
		And CurrentData.Price <> 0 Then
		
		Header.Areas.OfferPrice.Picture   = PictureLib.VarianceIsGreaterCommercialProposals;
		Header.Areas.OfferPrice.TextColor = StyleColors.RequiredAttributeEDLColor;
		
	EndIf;
	
	If CurrentData.Count < QueryStringData.QueryQuantity 
		And QueryStringData.QueryQuantity <> 0 
		And CurrentData.Count <> 0  Then
		
		Header.Areas.OfferQuantity.Picture   = PictureLib.VarianceIsLessCommercialProposals;
		Header.Areas.OfferQuantity.TextColor = StyleColors.RequiredAttributeEDLColor;
		
	ElsIf CurrentData.Count > QueryStringData.QueryQuantity
		And Not Object.PartialSaleAllowed
		And QueryStringData.QueryQuantity <> 0 
		And CurrentData.Count <> 0  Then 
		
		Header.Areas.OfferQuantity.Picture   = PictureLib.VarianceIsGreaterCommercialProposals;
		Header.Areas.OfferQuantity.TextColor = StyleColors.RequiredAttributeEDLColor;
		
	EndIf;
	
	InformationRequestedOfferedOnString.Put(Header, Undefined, "Header", True);
	InformationRequestedOfferedOnString.FixedTop = 3;
	InformationRequestedOfferedOnString.PageHeight = 3;
	
EndProcedure

&AtClient
Procedure UpdateInformationRequestedRequestedIfRequested(CurrentData)
	
	If OnRequest Then
		
		GenerateInformationRequestedSuggestedByLine(CurrentData.GetID());
		
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithRequestedStrings

&AtClientAtServerNoContext
Procedure DetermineOfferNumbersForQueryString(Form, RowIDRequest)
	
	SearchParameters = New Structure;
	SearchParameters.Insert("RowIDRequest", RowIDRequest);
	
	FoundRows = Form.Object.Goods.FindRows(SearchParameters);
	OfferNumberForTheRequestLine = 1;
	
	For Each FoundRow In FoundRows Do
		
		FoundRow.OfferNumberForTheRequestLine = OfferNumberForTheRequestLine;
		OfferNumberForTheRequestLine = OfferNumberForTheRequestLine + 1; 
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DeleteLinesWithSuggestionsForQueryString(RowIDRequest)

	SearchParameters = New Structure;
	SearchParameters.Insert("RowIDRequest", RowIDRequest);
	
	FoundRows = Object.Goods.FindRows(SearchParameters);
	
	For Each FoundRow In FoundRows Do
		Object.Goods.Delete(FoundRow);
	EndDo;

EndProcedure

&AtClient
Procedure DeleteQueryString(RowData)

	RowIDRequest = RowData.RowIDRequest;
	
	Object.Goods.Delete(RowData);
	DetermineOfferNumbersForQueryString(ThisObject, RowIDRequest);

EndProcedure

&AtClient
Procedure AddLineByQueryPosition()
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	NewRow = Object.Goods.Insert(Object.Goods.IndexOf(CurrentData)+1);
	NewRow.RowIDRequest = CurrentData.RowIDRequest;
	DetermineOfferNumbersForQueryString(ThisObject, CurrentData.RowIDRequest);
	
	Items.Goods.CurrentRow  = NewRow.GetID();
	Items.Goods.CurrentItem = Items.GoodsProducts;
	Items.Goods.ChangeRow();
	
EndProcedure

&AtServer
Procedure RecalculateRequestPrice()

	ConversionRatioFromTheQueryCurrencyToTheDocumentCurrency = CommercialProposalsDocuments.ConversionRateFromCurrencyToCurrency(RequestCurrency_2, Object.Currency, Object.Date);
	
	For Each RowOfProductsTable In Object.Goods Do
		
		RowOfProductsTable.RequestPriceDocumentCurrency = RowOfProductsTable.QueryPrice * ConversionRatioFromTheQueryCurrencyToTheDocumentCurrency;
		
	EndDo;
	
	If Items.Goods.CurrentRow <> Undefined Then
		GenerateInformationRequestedSuggestedByLine(Items.Goods.CurrentRow);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormationOfPresentations

&AtServer
Procedure FormPresentationOfFoundationDocument()

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	
	BaseDocumentPresentation = CommercialProposalsDocuments.BaseDocumentPresentation(Object.DocumentBasis);

EndProcedure

&AtServer
Procedure FormCaptionAttachedFiles()
	
	AttachedFilesCount = 0;
	Size = 0;
	
	FormObject = Object;
	
	If Not FormObject.Ref.IsEmpty() Then
		
		CatalogName = "Catalog." + FormObject.Ref.Metadata().Name + "AttachedFiles";
		
		Query = New Query;
		Query.Text = "
		|SELECT ALLOWED
		|	COUNT(DISTINCT TableName.Ref) AS FilesCount,
		|	ISNULL(SUM(TableName.Size), 0)   AS Size
		|FROM
		|	&CatalogName AS TableName
		|WHERE
		|	NOT TableName.DeletionMark
		|	AND TableName.CIDAttachHTML = """"
		|	AND TableName.FileOwner   = &FileOwner";
		
		Query.SetParameter("FileOwner", FormObject.Ref);
		
		Query.Text = StrReplace(Query.Text, "&CatalogName", CatalogName);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		AttachedFilesCount = Selection.FilesCount;
		Size = Round(Selection.Size / 1024 / 1024, 0);
		
	EndIf;
	
	Rows = New Array;
		Color = ?(Size > 60, StyleColors.OverdueDataColor, StyleColors.NoteText);
	
	PresentationOfAttachedFiles = NStr("vi = 'Tệp để gửi cho khách hàng';
										|ru = 'Файлы для отправки клиенту';
										|en = 'Files to send to customer'; fa = 'Files to send to customer';
										|it = 'File per l''invio al client';
										|pl = 'Pliki do wysyłki klientowi';
										|tr = 'Müşteriye gönderilecek dosyalar'");
		
	If ValueIsFilled(AttachedFilesCount) Then 
		Rows.Add(New FormattedString(StrTemplate(NStr("vi = '%1 (%2)';
														|ru = '%1 (%2)';
														|en = '%1 (%2)'; fa = '%1 (%2)';
														|it = '%1 (%2)';
														|pl = '%1 (%2)';
														|tr = '%1 (%2)'"),
			PresentationOfAttachedFiles, AttachedFilesCount),,,,"Open"));
		Rows.Add(". ");
		Rows.Add(New FormattedString(StrTemplate(NStr("vi = '%1 Mb.';
														|ru = '%1 Мб.';
														|en = '%1 MB.'; fa = '%1 MB.';
														|it = '%1 Мb.';
														|pl = '%1 MB.';
														|tr = '%1 Mb'"), Size),,Color));
	Else
		Rows.Add(New FormattedString(PresentationOfAttachedFiles,,,,"Open"));
	EndIf;
	
	Items.OpenAttachedFiles.Title            = New FormattedString(Rows);
	Items.OpenAttachedFiles.ToolTipRepresentation = ?(Size > 60, ToolTipRepresentation.Button, ToolTipRepresentation.None);
	
EndProcedure


#EndRegion

#Region ResultsInitialFilling

&AtServer
Function BasedOnRequestForCommercialOffer()

	Result = False;
	
	
	Return Result;

EndFunction

&AtServer
Procedure OnCreatReadAtServer()

	OnRequest = BasedOnRequestForCommercialOffer();
	
	AccountingSettings = CommercialProposalsDocuments.AccountingSettings();
	
	NotPartialSaleAllowed = Not Object.PartialSaleAllowed;
	
	FormCaptionAttachedFiles();
	DetermineAvailabilityOfAdditionalInformation(ThisObject);
	
	FillInDependentDetailsOfTablePart();
	VATTaxation = CommercialProposalsDocumentsClientServerTM.TaxationOfVATOnTaxationOfCommercialOffers(Object.Taxation);
	If Object.Taxation Then
		OrganizationAccountingParameters = VATAccountingERP.AccountingParametersForOrganization(Object.Organization,Object.Date);
		VATTaxation = OrganizationAccountingParameters.BasicTaxationVATSales;
	EndIf;
	CustomizeFormElements();
	AvailabilityControl(ThisObject);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInDependentDetailsOfTablePart(ArrayOfIDsOfAddedRows = Undefined)
	
	If ArrayOfIDsOfAddedRows <> Undefined
		And ArrayOfIDsOfAddedRows.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	
	CommercialProposalsDocuments.DetectPresenceOfCommentsInLines(
		ThisObject, "Goods", "CommentForCustomer", "InternalComment", "HasComment");

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	CommercialProposalsDocuments.EstablishConditionalAppearanceOfVATAmounts(ThisObject);
	CommercialProposalsDocuments.SetConditionalAppearancePriceIncludesVAT(ThisObject);
	
	CommercialProposalsDocumentsOverridable.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
#Region StoppedBeingReviewed
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StoppedBeingReviewed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsQueryLineNumber");
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsCustomerProductsPresentation");
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsQueryDeliveryPeriodPresentation");
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsQueryQuantity");
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsQueryUnitOfMeasure");
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("ProductsInquiryPrice");
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Font", New Font(Items.GoodsCustomerProductsPresentation.Font
	                                                                  ,,,,,,True));
	
#EndRegion

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.WasChanged");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsWasChanged");
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	CommercialProposalsDocumentsOverridable.WhenSettingConditionalAppearance(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFormTotals(Form)

	CollectionProducts = Form.Object.Goods;
	
	Form.VATAmount           = CollectionProducts.Total("VATAmount");
	Form.DocumentAmountWithVAT = CollectionProducts.Total("AmountIncludingVAT");
	AmountExcludingVAT              = CollectionProducts.Total("Sum");
	
	AutoDiscountAmount   = CollectionProducts.Total("DiscountMarkupAmount");
	ManualDiscount = CollectionProducts.Total("ManualDiscount");

	Form.DiscountAmount = AutoDiscountAmount + ManualDiscount;
	
	If AmountExcludingVAT > 0 Then
		AutoDiscountPercentage   = AutoDiscountAmount * 100 / (AmountExcludingVAT + Form.DiscountAmount);
		PercentRateOfManualDiscount = ManualDiscount * 100 / (AmountExcludingVAT + Form.DiscountAmount);
		Form.DiscountPercentage = AutoDiscountPercentage + PercentRateOfManualDiscount;
	ElsIf Form.DiscountAmount > 0 Then
		Form.DiscountPercentage       = 100;
	Else
		Form.DiscountPercentage       = 0;
	EndIf;
	
	If Form.Object.Taxation Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_CalculateFormTotals() Export

	CalculateFormTotals(ThisObject);

EndProcedure

#EndRegion

#Region CompletionOfFormCommands

&AtServer
Procedure ProcessingProductSelectionResults(ValueSelected, AdditionalParameters, ProcessingResult)
	
	CommercialProposalsDocumentsOverridable.ProcessingProductSelectionResults(
		ThisObject, ValueSelected, AdditionalParameters, ProcessingResult);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		CommercialProposalsDocumentsClientOverridable.WhenChangingQuantity(ThisObject, CurrentRow);
		CommercialProposalsDocumentsClientOverridable.WhenChangingQuantity(ThisObject, NewRow);
		
		Items.Goods.CurrentRow = NewRow.GetID();
		
		NewRow.CustomerProductsPresentation = "";
		NewRow.QueryLineNumber                   = 0;
		NewRow.QueryDeliveryPeriodPresentation     = "";
		NewRow.QueryQuantity                    = 0;
		NewRow.QueryPrice                          = 0;
		NewRow.RequestPriceDocumentCurrency           = 0;
		NewRow.QueryUnitOfMeasure              = Undefined;
		
		DetermineOfferNumbersForQueryString(ThisObject, NewRow.RowIDRequest);
		
		CalculateFormTotals(ThisObject);
		
	EndIf;

EndProcedure

&AtClient
Procedure DeliveryPeriodDaysCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each RowIndex In Items.Goods.SelectedRows Do
		
		CurrentRow = Items.Goods.RowData(RowIndex);
		CurrentRow.DeliveryPeriodDays = Result;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ProcessingProductSelectionResults(Result, AdditionalParameters) Export
	
	ServerCallRequired__ = False;
	ProcessingResult = Undefined;
	
	CommercialProposalsDocumentsClientOverridable.AfterProductSelectionProcess(ThisObject, 
	                                                                                          Result, 
	                                                                                          AdditionalParameters,
	                                                                                          ServerCallRequired__);
	
	If ServerCallRequired__ Then
		ProcessingProductSelectionResults(Result, AdditionalParameters, ProcessingResult);
		CommercialProposalsDocumentsClientOverridable.AfterProcessingAndSelectingProducts(ThisObject,
		                                                                                                   Result,
		                                                                                                   ProcessingResult, 
		                                                                                                   AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingTypeOfPrice(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		FillInPricesByTypeOfPricesOnServer(Result, AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingSalesCondition(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		FillInPricesAccordingToSalesConditionOnServer(Result, AdditionalParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillingInDocument_

&AtServer
Procedure FillInPricesByTypeOfPricesOnServer(PriceKind, AdditionalParameters)
	
	CommercialProposalsDocumentsOverridable.FillInPricesByPriceKind(ThisObject, PriceKind, AdditionalParameters);
	CalculateFormTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInPricesAccordingToSalesConditionOnServer(ConditionOfSale, AdditionalParameters)
	
	CommercialProposalsDocumentsOverridable.FillInPricesBySalesCondition(ThisObject, ConditionOfSale, AdditionalParameters);
	CalculateFormTotals(ThisObject);
	
EndProcedure

#EndRegion

#Region BarcodeInputProcessing

&AtClient
Procedure SearchByBarcodeCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ProcessingResult = Undefined;
	ProcessBarcodeInput(Result, ProcessingResult);
	
	CommercialProposalsDocumentsClientOverridable.AfterProcessingBarcodes_(ThisObject, ProcessingResult);

EndProcedure

&AtServer
Procedure ProcessBarcodeInput(BarcodeData_1, ProcessingResult)
	
	CommercialProposalsDocumentsOverridable.ProcessBarcodeInput(ThisObject, BarcodeData_1, ProcessingResult);
	CalculateFormTotals(ThisObject);
	
EndProcedure

#EndRegion

#Region LoadingTSDData

&AtClient
Procedure DownloadFromTSDCompletion(ExecutionResult, AdditionalParameters) Export
	
	CallbackOnCompletion = New CallbackDescription("Attachable_ReceivedDataFromTSD", ThisObject);
	
	CommercialProposalsDocumentsClientOverridable.WhenReceivingDataFromTSD(CallbackOnCompletion, ThisObject, ExecutionResult);
	
EndProcedure

&AtClient
Procedure Attachable_ReceivedDataFromTSD(TableOfGoods, AdditionalParameters) Export
	
	If TableOfGoods.Count() = 0 Then
		
		ShowMessageBox( ,NStr("vi = 'Dữ liệu nhận được không chứa thông tin về mã vạch đã đọc';
								|ru = 'В полученных данных не содержится информации о считанных штриховых кодах';
								|en = 'The retrieved data do not contain the information about read barcodes'; fa = 'The retrieved data do not contain the information about read barcodes';
								|it = 'I dati ottenuti non contengono informazioni sui codici a barre letti.';
								|pl = 'W otrzymanych danych nie ma informacji na temat odczytanych kodów kreskowych';
								|tr = 'Alınan veriler okunan barkodlar hakkında bilgi içermez'"));
		Return;
		
	EndIf;
	
	ProcessingResult = Undefined;
	
	ProcessReceivedTSDData(TableOfGoods, ProcessingResult);
	CommercialProposalsDocumentsClientOverridable.AfterProcessingBarcodes_(ThisObject, ProcessingResult);
	
EndProcedure

&AtServer
Procedure ProcessReceivedTSDData(TableOfGoods, ProcessingResult)
	
	CommercialProposalsDocumentsOverridable.ProcessReceivedTSDData(ThisObject, TableOfGoods, ProcessingResult);
	
EndProcedure

#EndRegion

#Region ServerSideEventHandlersForFormElements

&AtServer
Procedure GoodsManualDiscountOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingAmountOfManualDiscount(
	         ThisObject,
	         CurrentData,
	         Object.PriceIncludesVAT,
	         Object.Taxation);
	
EndProcedure

&AtServer
Procedure GoodsPercentRateOfManualDiscountOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingPercentageOfManualDiscount(
	        ThisObject,
	        CurrentData,
	        Object.PriceIncludesVAT,
	        Object.Taxation);
	
EndProcedure

&AtServer
Procedure ProductsVATAmountWhenChangingServerChanges()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingVATAmount(ThisObject, CurrentData, Object.PriceIncludesVAT);
	
EndProcedure

&AtServer
Procedure GoodsVATRateOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingVATRate(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure GoodsSumOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingAmount(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure GoodsPriceKindOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingPriceType(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure GoodsPriceOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenPriceChanges(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure GoodsCountOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingQuantity(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure GoodsUnitOfMeasureOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingUnitOfMeasurement(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure GoodsCharacteristicOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingCharacteristics(ThisObject,
	                                                                            CurrentData);
	
EndProcedure

&AtServer
Procedure GoodsProductsOnChangeServer()
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingProducts(ThisObject, 
	                                                                          CurrentData, 
	                                                                          "Products");
	
EndProcedure

&AtServer
Procedure GoodsSelectionServer(FieldName, ProcessingResult)
	
	CommercialProposalsDocumentsOverridable.GoodsSelectionServer(ThisObject, FieldName, ProcessingResult);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenOrganizationChanges(ThisObject);
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenChangingContactPerson(ThisObject);
	
EndProcedure

&AtServer
Procedure ManagerOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenChangingManager(ThisObject);
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenStatusChanges(ThisObject, CurrentSessionDate());
	
EndProcedure

&AtServer
Procedure NotPartialSaleAllowedOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenChangingFlagCanBeRedeemedPartially(ThisObject);
	
EndProcedure

&AtServer
Procedure OperationOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenBusinessTransactionChanges(ThisObject);
	
EndProcedure

&AtServer
Procedure ValidityPeriodOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenChangingValidityPeriodOfCommercialOffer(ThisObject,
	                                                                                                   CurrentSessionDate());
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	If OnRequest Then
		RecalculateRequestPrice();
	EndIf;
	
	CommercialProposalsDocumentsOverridable.WhenChangingCurrency(ThisObject);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	RecalculateRequestPrice();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenChangingCounterparty(ThisObject);
	
EndProcedure

&AtServer
Procedure ClientOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenChangingPartner(ThisObject);
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.OnChangePriceIncludesVAT(ThisObject, Object.Taxation);
	
EndProcedure

&AtServer
Procedure TaxationOnChangeServer()
	
	CommercialProposalsDocumentsOverridable.WhenChangingVATTaxation(ThisObject);
	
EndProcedure

&AtServer
Procedure OverridableServerCommand(CommandName, Result)

	CommercialProposalsDocumentsOverridable.WhenExecutingOverridableCommand(ThisObject, CommandName, Result);

EndProcedure

#EndRegion

#Region Discounts

&AtServer
Procedure CalculateDiscountsOnServer(ProcessingResult)
	
	CommercialProposalsDocumentsOverridable.CalculateDiscountsOnServer(ThisObject, ProcessingResult);
	
EndProcedure

&AtServer
Procedure PrepareOpeningInformationAboutDiscountsOnServer(ProcessingResult)
	
	CommercialProposalsDocumentsOverridable.PrepareOpeningInformationAboutDiscountsOnServer(ThisObject, ProcessingResult);
	
EndProcedure

&AtServer
Procedure WhenCancelingManualDiscountsOnServer(ProcessingResult)
	
	CommercialProposalsDocumentsOverridable.WhenCancelingManualDiscountsOnServer(ThisObject, ProcessingResult);
	
EndProcedure

&AtServer
Procedure WhenAssigningManualDiscountOnServer(ProcessingResult)
	
	 CommercialProposalsDocumentsOverridable.WhenAssigningManualDiscountOnServer(ThisObject, ProcessingResult);
	
EndProcedure

&AtServer
Procedure AfterAssigningManualDiscountOnServer(ProcessingResult, Val SelectedRows, AdditionalParameters)
	
	CommercialProposalsDocumentsOverridable.AfterAssigningManualDiscountOnServer(ThisObject, SelectedRows, ProcessingResult, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure WhenAssigningAutomaticDiscountsOnServer(Result)

	CommercialProposalsDocumentsOverridable.WhenAssigningAutomaticDiscountsOnServer(ThisObject, Result);

EndProcedure

&AtServer
Procedure AfterAssigningAutomaticDiscountOnServer(Result, AdditionalParameters)
	
	CommercialProposalsDocumentsOverridable.AfterAssigningAutomaticDiscountOnServer(ThisObject, Result, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure SuggestUserToCalculateDiscountsCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		CalculateDiscounts(Undefined);
	EndIf;
	
	AdditionalParameters.AnswerToQuestionAboutCalculatingDiscountsIsReceived = True;
	Write(AdditionalParameters);
	
EndProcedure

#EndRegion

#Region CopyRows

&AtServer
Procedure CopyLinesOnServer()
	
	StandardProcessing = True;
	
	CommercialProposalsDocumentsOverridable.WhenCopyingLinesToClipboard(ThisObject,
	                                                                                 Object.Goods,
	                                                                                 Items.Goods.SelectedRows, 
	                                                                                 "Goods",
	                                                                                 StandardProcessing);
	
	If StandardProcessing Then
		
		Common.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows, "Goods");
		
	EndIf;
	
EndProcedure

&AtServer
Function ResultOfInsertingRows()
	
	StandardProcessing = True;
	RowsCount      = 0;
	
	CommercialProposalsDocumentsOverridable.WhenPastingLinesFromClipboard(ThisObject, RowsCount, StandardProcessing);

	If StandardProcessing Then
		
		DataFromClipboard = Common.RowsFromClipboard();
		If DataFromClipboard.Source <> "Goods" Then
			Return 0;
		EndIf;
		
		For Each TableRow In DataFromClipboard.Data Do
			FillPropertyValues(Object.Goods.Add(), TableRow);
		EndDo;
		
		RowsCount = DataFromClipboard.Data.Count();
	
	EndIf;
	
	CalculateFormTotals(ThisObject);
	
	Return RowsCount;
	
EndFunction

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_ValidityPeriod" Then
		ValidityPeriodOnChange(Items.ValidityPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
