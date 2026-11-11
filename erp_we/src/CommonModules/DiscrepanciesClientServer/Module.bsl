
////////////////////////////////////////////////////////////////////////////////
// The "Divergenclientserver" module contains procedures and functions running on the client and server
// for the operation of documents to reflect discrepancies after shipment.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice")
	        Or TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.EmptyRef");
	
EndFunction

Function TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBaseDocumentForNonConformanceCertificate =
				PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer");
	
EndFunction

Function TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	TypesOfActGrounds = New Array;
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor"));
	Return TypesOfActGrounds.Find(TypeOfBaseDocumentForNonConformanceCertificate) <> Undefined;
	
EndFunction

Function TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent");
	
EndFunction

Function TypeOfBasisGoodsReceiptForStorage(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	TypesOfActGrounds = New Array;
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider"));
	Return TypesOfActGrounds.Find(TypeOfBaseDocumentForNonConformanceCertificate) <> Undefined;
	
EndFunction

Function TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	TypesOfActGrounds = TypesOfBasisReceiptOfGoodsFromCustodian();
	
	Return TypesOfActGrounds.Find(TypeOfBaseDocumentForNonConformanceCertificate) <> Undefined;
	
EndFunction

Function TypeOfBasisPurchaseOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice");
	
EndFunction

Function TypeOfBasisReturnOfGoodsFromCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBaseDocumentForNonConformanceCertificate =
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer");
	
EndFunction

Function TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBaseDocumentForNonConformanceCertificate =
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor");
	
EndFunction

Function TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBaseDocumentForNonConformanceCertificate =
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage");
	
EndFunction

Function TypeOfBasisMovementOfGoods(DocumentRef) Export
	
	Return TypeOf(DocumentRef) = Type("DocumentRef.DiscrepancyReportFollowingTransfer");
	
EndFunction

Function TypesOfBasisReceiptOfGoodsFromCustodian() Export
	
	BaseTypes = New Array;
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian"));
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent"));
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor"));
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor"));
	Return BaseTypes;
	
EndFunction

Function TypeOfBasisRefundFromCommissionAgent(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent");
	
EndFunction

// All types of grounds for the act of discrepancies after shipment.
//
// Returns:
//  Array of EnumRef.TypesOfBaseDocumentsForDiscrepancyReport -
Function TypesOfGroundsForActOfDiscrepanciesAfterShipment() Export
	
	TypesOfActGrounds = New Array;
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider"));
	Return TypesOfActGrounds;
	
EndFunction

// All types of grounds for the act of discrepancies after acceptance.
//
// Returns:
//  Array of EnumRef.TypesOfBaseDocumentsForDiscrepancyReport -
Function TypesOfGroundsForActOfDiscrepanciesAfterAcceptance() Export
	
	TypesOfActGrounds = TypesOfBasisReceiptOfGoodsFromCustodian(); // Array -
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage"));
	TypesOfActGrounds.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider"));
	Return TypesOfActGrounds;
	
EndFunction

Function VATIsNotRecorded(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	BaseTypes = New Array;
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer"));
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage"));
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage"));
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider"));
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider"));
	BaseTypes.Add(
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider"));
	Return BaseTypes.Find(TypeOfBaseDocumentForNonConformanceCertificate) <> Undefined;
	
EndFunction

Function CalculateFinalQuantitativeIndicatorsOfForm(GoodsTable) Export
	
	Result = New Structure;
	Result.Insert("Shortages", 0);
	Result.Insert("Surpluses", 0);
	Result.Insert("Discrepancies", 0);
	Result.Insert("LinesWithDiscrepancies", 0);
	
	Result.Shortages = 0;
	Result.Surpluses   = 0;
	
	For Each LineProducts_ In GoodsTable Do
		
		If LineProducts_.NumberOfDiscrepancyPackaging <> 0 Then
			Result.LinesWithDiscrepancies = Result.LinesWithDiscrepancies + 1;
		EndIf;
		
		If LineProducts_.NumberOfDiscrepancyPackaging > 0 Then
			Result.Surpluses = Result.Surpluses + LineProducts_.NumberOfDiscrepancyPackaging;
		ElsIf LineProducts_.NumberOfDiscrepancyPackaging < 0 Then
			Result.Shortages = Result.Shortages + (-LineProducts_.NumberOfDiscrepancyPackaging);
		EndIf;
		
	EndDo;
	
	Result.Insert("ThereAreSurpluses", Result.Surpluses > 0);
	Result.Insert("ThereIsShortages", Result.Shortages > 0);
	
	Result.Discrepancies = GoodsTable.Total("Count") - GoodsTable.Total("CountByDocument");
	
	Return Result;
	
EndFunction

Function StructureOfActionsWhenChangingNumberOfPackages() Export

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateDiscrepancies");

	Return StructureOfActions;

EndFunction

Function StructureOfActionsFillInDependentDetailsOfGoods() Export

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateDiscrepancies");
	StructureOfActions.Insert("SetFlagForFillingInTextDescription");
	StructureOfActions.Insert("FlagForComment");

	Return StructureOfActions;

EndFunction

Function ActionStructureFillInDependentDetailsOfGoodsDiscrepanciesAfterShipment() Export

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	StructureOfActions.Insert("SetFlagForFillingInTextDescription");
	StructureOfActions.Insert("FlagForShipmentComment");

	Return StructureOfActions;

EndFunction

Function ActionStructureFillInDependentDetailsOfGoodsDiscrepanciesAfterAcceptance() Export

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	StructureOfActions.Insert("FlagForAcceptanceComment");

	Return StructureOfActions;

EndFunction

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - 
// 		* Items - FormItems - 
// 
Procedure AvailabilityControl(Form) Export
	
	InfluencingPropsAreAvailable = Form.BasisDocuments.Count() = 0;
	
	If TypeOfBasisMovementOfGoods(Form.Object.Ref) Then
		
		SelectionOfDocumentsIsNotAvailable = ValueIsFilled(Form.Object.SourceWarehouse)
		                                    And ValueIsFilled(Form.Object.DestinationWarehouse)
		                                    And ValueIsFilled(Form.Object.Organization);
		
	ElsIf TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		SelectionOfDocumentsIsNotAvailable = (Not Form.ToUseTermsOfSales Or ValueIsFilled(Form.Object.Terms))
		                                    And ValueIsFilled(Form.Object.Partner)
		                                    And ValueIsFilled(Form.Object.Counterparty)
		                                    And ValueIsFilled(Form.Object.Organization)
		                                    And ?(Form.Items.Contract.Visible And Form.ToUseTermsOfSales,
		                                        ValueIsFilled(Form.Object.Contract), True)
		                                    And ValueIsFilled(Form.Object.Currency)
		                                    And (ValueIsFilled(Form.Object.VATTaxation)
		                                        Or Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		                                        Or Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"))
		                                    And ValueIsFilled(Form.Object.BusinessOperation);
		
	ElsIf TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisRefundFromCommissionAgent(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
		
		SelectionOfDocumentsIsNotAvailable = ?(TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate),
												Not Form.ToUseTermsOfSales
													Or ValueIsFilled(Form.Object.Terms),
												True)
							And ValueIsFilled(Form.Object.Partner)
							And ValueIsFilled(Form.Object.Counterparty)
							And ValueIsFilled(Form.Object.Organization)
							And ValueIsFilled(Form.Object.Currency)
							And ValueIsFilled(Form.Object.BusinessOperation)
							And ?(TypeOfBasisRefundFromCommissionAgent(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate),
								ValueIsFilled(Form.Object.Contract), True);
		
	Else
		
		SelectionOfDocumentsIsNotAvailable = ValueIsFilled(Form.Object.Partner)
		                                    And ValueIsFilled(Form.Object.Counterparty)
		                                    And ValueIsFilled(Form.Object.Organization)
		                                    And ValueIsFilled(Form.Object.Currency)
		                                    And (ValueIsFilled(Form.Object.VATTaxation)
		                                        Or Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		                                        Or Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian"))
		                                    And ValueIsFilled(Form.Object.BusinessOperation);
		
	EndIf;
	
	ProductSelectionIsAvailable = SelectionOfDocumentsIsNotAvailable And (Form.BasisDocuments.Count() > 0);
	
	Form.Items.Organization.ReadOnly           = Not InfluencingPropsAreAvailable;
	
	If Not TypeOfBasisMovementOfGoods(Form.Object.Ref) Then
		
		Form.Items.Partner.ReadOnly               = Not InfluencingPropsAreAvailable;
		Form.Items.Counterparty.ReadOnly            = Not InfluencingPropsAreAvailable;
		Form.Items.Terms.ReadOnly            = Not InfluencingPropsAreAvailable;
		Form.Items.Contract.ReadOnly               = Not InfluencingPropsAreAvailable;
		Form.Items.Currency.ReadOnly                = Not InfluencingPropsAreAvailable;
		Form.Items.PriceIncludesVAT.ReadOnly       = Not InfluencingPropsAreAvailable;
		Form.Items.VATTaxation.ReadOnly    = Not InfluencingPropsAreAvailable;
		Form.Items.BusinessOperation.ReadOnly = Not InfluencingPropsAreAvailable;
		Form.Items.BusinessOperation.ReadOnly = Not InfluencingPropsAreAvailable
									Or TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
									Or TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
									Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
									Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
									Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider")
									Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage");
		
	EndIf;
	
	EditFoundationDocumentsElement     = Form.Items.ChangeBaseDocuments; // FormDecoration
	FillInProductsElementBasedOnFollowingReasons    = Form.Items.GoodsFillInByBasis; // CommandBarButton
	LoadProductsFromExternalFile = Form.Items.GoodsImportFromExternalFile; // CommandBarButton
	ProductsOpenSelectionElement            = Form.Items.GoodsOpenSelection; // CommandBarButton
	AddProductsElement                 = Form.Items.GoodsAdd; // CommandBarButton
	Item_Products                         = Form.Items.Goods; // CommandBarButton
	
	EditFoundationDocumentsElement.Enabled     = SelectionOfDocumentsIsNotAvailable;
	FillInProductsElementBasedOnFollowingReasons.Enabled    = ProductSelectionIsAvailable;
	LoadProductsFromExternalFile.Enabled = ProductSelectionIsAvailable;
	ProductsOpenSelectionElement.Enabled            = ProductSelectionIsAvailable;
	AddProductsElement.Enabled                 = ProductSelectionIsAvailable;
	Item_Products.Enabled                         = ProductSelectionIsAvailable;
	
	If TypeOfBasisMovementOfGoods(Form.Object.Ref) Then
		// Not processed
	ElsIf TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then 
		
		ManagingWayDivergenceIsReflectedImplementation(Form);
	
	ElsIf TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		ManagingWayDiscrepanciesAreReflectedShipmentOfItemsToCustomer(Form);
		
	ElsIf TypeOfBasisPurchaseOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		ManagingWayDiscrepancyIsReflectedAcquisition(Form);
		
	ElsIf TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		ManagingWayDiscrepancyIsReflectedTransfer(Form);
		
	ElsIf TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
			PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
			PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider")
		Then
		
		ManagingWayDiscrepanciesAreReflectedShipment(Form);
		
	ElsIf TypeOfBasisGoodsReceiptForStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		ManagingWayDiscrepanciesAreReflectedAcceptanceAndReceipt(Form);
		
	EndIf;
	
	InscriptionIssueDocuments = Form.Items.IssueDocuments;//FormDecorationExtensionForALabel
	
	If (Form.ActLinesContainActionsThatRequireProcessing
	      And ValueIsFilled(Form.Object.DiscrepanciesPostingMethod)
	      And (Form.Object.Status = PredefinedValue("Enum.StatusesOfDiscrepancyReport.ForCompletion")
	      Or Form.Object.Status = PredefinedValue("Enum.StatusesOfDiscrepancyReport.Processed_"))) Then
	      	
		InscriptionIssueDocuments.Hyperlink = True;
		InscriptionIssueDocuments.Title   = NStr("vi = 'Lập chứng từ';
												|ru = 'Оформить документы';
												|en = 'Issue documents'; fa = 'صدور اسناد';
												|it = 'Regolarizzare i documenti';
												|pl = 'Sporządź dokumenty';
												|tr = 'Evrakları hazırlayın'");
		InscriptionIssueDocuments.Enabled = True;
		
	Else
		
		InscriptionIssueDocuments.Hyperlink = False;
		InscriptionIssueDocuments.Enabled = False;
		
		InscriptionIssueDocuments.Title  = NStr("vi = 'Cho phép lập chứng từ khi có chênh lệch trong trạng thái ""Đang xử lý"" và ""Đã xử lý""';
												|ru = 'Оформление документов доступно при наличии расхождений в статусах ""Отрабатывается"" и ""Отработано""';
												|en = 'Document registration is available if there are discrepancies in the ""In progress"" and ""Processed"" statuses'; fa = 'Document registration is available if there are discrepancies in the ""In progress"" and ""Processed"" statuses';
												|it = 'La formalizzazione dei documenti è disponibile in caso di presenza di discrepanze negli stati ""In lavorazione"" e ""Lavorato""';
												|pl = 'Sporządzenie dokumentów jest dostępne w przypadku odchylenia w statusach ""Opracowuje się"" oraz ""Opracowano""';
												|tr = '""İşleniyor"" ve ""İşlendi"" durumlarında bir tutarsızlık varsa belge düzenlemesi kullanılabilir'");
		
	EndIf;
	
	FormEventsClientServer.WhenChangingElement(Form, Form.Items.IssueDocuments.Name);
	
	CommonClientServer.SetFormItemProperty(Form.Items,
	                                                             "ProductsFillInAcceptanceCertificate",
	                                                             "Enabled",
	                                                             Form.Object.Goods.Count() > 0);
	
	ProductsChangeActionElement = Form.Items.GoodsChangeAction; // CommandBarButton
	
	ProductsChangeActionElement.Enabled = Form.ThereAreSurpluses Or Form.ThereIsShortages;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
// 
Procedure ManagingWayDiscrepancyIsReflectedAcquisition(Form)
	
	Object                        = Form.Object;
	Items                      = Form.Items;
	AvailableWaysOfProcessingTheCertificate = Form.AvailableWaysOfProcessingTheCertificate;
	
	If Not (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt")) Then
				
		Items.HowToReflectDiscrepanciesDocumentChanges.Visible = True;
		Items.MethodForReflectingDiscrepanciesRevenueAdjustment.Visible = False;
		Items.GroupInformationAboutAvailabilityOfTheRecordMethod.Visible = False;	
		
	Else
		
		Items.HowToReflectDiscrepanciesDocumentChanges.Enabled = 
			AvailableWaysOfProcessingTheCertificate.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments")) <> Undefined;
		
		Items.MethodForReflectingDiscrepanciesRevenueAdjustment.Enabled = 
			AvailableWaysOfProcessingTheCertificate.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries")) <> Undefined;
		
	EndIf;
	
	MethodMismatchMessageRequired = False;
	DetermineNeedForMethodMismatch(Object, AvailableWaysOfProcessingTheCertificate, MethodMismatchMessageRequired);
	
	ExplanationText = ExplanationTextMethodOfWorkingOutActAfterAcquisition(Form, MethodMismatchMessageRequired);
	ConfigureFormElementsToReflect(Object, Items, MethodMismatchMessageRequired, ExplanationText);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
// 
Procedure ManagingWayDiscrepancyIsReflectedTransfer(Form)
	
	Object                        = Form.Object;
	Items                      = Form.Items;
	AvailableWaysOfProcessingTheCertificate = Form.AvailableWaysOfProcessingTheCertificate;
	
	Items.HowToReflectDiscrepanciesDocumentChanges.Enabled = 
		AvailableWaysOfProcessingTheCertificate.FindByValue(
			PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")) <> Undefined;

	Items.MethodForReflectingDiscrepanciesCorrectionCorrection.Enabled = 
		Form.UseDocumentCorrection
		And AvailableWaysOfProcessingTheCertificate.FindByValue(
			PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection")) <> Undefined;
	
	MethodMismatchMessageRequired = False;
	DetermineNeedForMethodMismatch(Object, AvailableWaysOfProcessingTheCertificate, MethodMismatchMessageRequired);
	
	ExplanationText = ExplanationTextMethodOfWorkingOutActAfterTransfer(Form, MethodMismatchMessageRequired);
	ConfigureFormElementsToReflect(Object, Items, MethodMismatchMessageRequired, ExplanationText);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
//
Procedure ManagingWayDiscrepanciesAreReflectedShipment(Form)
	
	Object                        = Form.Object;
	Items                      = Form.Items;
	AvailableWaysOfProcessingTheCertificate = Form.AvailableWaysOfProcessingTheCertificate;
	
	Items.HowToReflectDiscrepanciesDocumentChanges.Enabled =
		AvailableWaysOfProcessingTheCertificate.FindByValue(
			PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")) <> Undefined;

	Items.MethodForReflectingDiscrepanciesCorrectionCorrection.Enabled =
		Form.UseDocumentCorrection
		And AvailableWaysOfProcessingTheCertificate.FindByValue(
			PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection")) <> Undefined;
	
	MethodMismatchMessageRequired = False;
	DetermineNeedForMethodMismatch(Object, AvailableWaysOfProcessingTheCertificate, MethodMismatchMessageRequired);
	
	ExplanationText = ExplanationTextMethodOfWorkingOutActAfterShipment(Form, MethodMismatchMessageRequired);
	ConfigureFormElementsToReflect(Object, Items, MethodMismatchMessageRequired, ExplanationText);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
// 
Procedure ManagingWayDiscrepanciesAreReflectedAcceptanceAndReceipt(Form)
	
	Object                        = Form.Object;
	Items                      = Form.Items;
	AvailableWaysOfProcessingTheCertificate = Form.AvailableWaysOfProcessingTheCertificate;
	
	Items.HowToReflectDiscrepanciesDocumentChanges.Enabled = 
		AvailableWaysOfProcessingTheCertificate.FindByValue(
			PredefinedValue("Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments")) <> Undefined;

	Items.MethodForReflectingDiscrepanciesRevenueAdjustment.Enabled = 
		Form.UseDocumentCorrection
		And AvailableWaysOfProcessingTheCertificate.FindByValue(
			PredefinedValue("Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries")) <> Undefined;
	
	MethodMismatchMessageRequired = False;
	DetermineNeedForMethodMismatch(Object, AvailableWaysOfProcessingTheCertificate, MethodMismatchMessageRequired);
	
	ExplanationText = ExplanationTextMethodOfWorkingOutActAfterAcceptanceAndReceipt(Form, MethodMismatchMessageRequired);
	ConfigureFormElementsToReflect(Object, Items, MethodMismatchMessageRequired, ExplanationText);
	
EndProcedure

Procedure DetermineNeedForMethodMismatch(Object, AvailableWaysOfProcessingTheCertificate, MethodMismatchMessageRequired);
	
	If ValueIsFilled(Object.DiscrepanciesPostingMethod)
		And AvailableWaysOfProcessingTheCertificate.FindByValue(Object.DiscrepanciesPostingMethod) = Undefined Then
			
		If Object.Status = PredefinedValue("Enum.StatusesOfDiscrepancyReport.Processed_")
			Or Object.Status = PredefinedValue("Enum.StatusesOfDiscrepancyReport.ForCompletion") Then
			
			MethodMismatchMessageRequired = True;
			
		Else
		
			If AvailableWaysOfProcessingTheCertificate.Count() = 0 Then
				Object.DiscrepanciesPostingMethod = Undefined;
			Else
				Object.DiscrepanciesPostingMethod = AvailableWaysOfProcessingTheCertificate[0].Value;
			EndIf;
				
		EndIf;	
		
	EndIf;
	
EndProcedure

Procedure ConfigureFormElementsToReflect(Object, Items, MethodMismatchMessageRequired, ExplanationText)
	
	Items.GroupInformationAboutAvailabilityOfTheRecordMethod.Visible = Not IsBlankString(ExplanationText);
	
	InformationAboutAvailabilityOfReflectionMethodElement = Items.InformationAboutTheAvailabilityOfTheReflectionMethod; // FormDecoration
	ElementGroupReflectionMethod = Items.GroupRecordMethod; // FormGroup
	
	InformationAboutAvailabilityOfReflectionMethodElement.Title       = ExplanationText;
	
	ElementGroupReflectionMethod.Enabled = Not (Object.Status = PredefinedValue("Enum.StatusesOfDiscrepancyReport.Processed_")
	                                            Or Object.Status = PredefinedValue("Enum.StatusesOfDiscrepancyReport.ForCompletion"));
	
	If MethodMismatchMessageRequired Then
		Items.PagesInformationRecordMethods.CurrentPage = Items.PageIssueInformationMethodOfRecord;
	Else
		Items.PagesInformationRecordMethods.CurrentPage = Items.PageNormalInformationMethodOfRecord;
	EndIf;
	
EndProcedure

Procedure ManagingWayDivergenceIsReflectedImplementation(Form)

	Object                        = Form.Object;
	Items                      = Form.Items;
	AvailableWaysOfProcessingTheCertificate = Form.AvailableWaysOfProcessingTheCertificate;
	
	If Object.BusinessOperation = 
					PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
			Or Object.BusinessOperation = 
					PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
		Then

		Items.HowToReflectDiscrepanciesDocumentChanges.Enabled = 
			AvailableWaysOfProcessingTheCertificate.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")) <> Undefined;

		Items.MethodForReflectingDiscrepanciesCorrectionCorrection.Enabled = 
			AvailableWaysOfProcessingTheCertificate.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection")) <> Undefined;
				
		Items.MethodOfReflectingDiscrepanciesAdjustmentByAgreement.Enabled = 
			AvailableWaysOfProcessingTheCertificate.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties")) <> Undefined;
		
		Items.MethodForReflectingDiscrepanciesAdjustmentNew.Enabled = 
			AvailableWaysOfProcessingTheCertificate.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments")) <> Undefined;

		If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
			Then
	
			If Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList.Count() > 0 Then
				Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList[0].Presentation =
					NStr("vi = 'Thay đổi chứng từ';
						|ru = 'Изменить документы';
						|en = 'Change documents'; fa = 'Change documents';
						|it = 'Change documents';
						|pl = 'Change documents';
						|tr = 'Belgeleri değiştir'");
			EndIf;
	
			If Items.MethodForReflectingDiscrepanciesCorrectionCorrection.ChoiceList.Count() > 0 Then
				Items.MethodForReflectingDiscrepanciesCorrectionCorrection.ChoiceList[0].Presentation =
					NStr("vi = 'Thực hiện điều chỉnh doanh số (sửa lỗi)';
						|ru = 'Оформить корректировку документов (исправление ошибок)';
						|en = 'Register document adjustment (error correction)'; fa = 'Register document adjustment (error correction)';
						|it = 'Register document adjustment (error correction)';
						|pl = 'Register document adjustment (error correction)';
						|tr = 'Müşterinin ürünlerinin sevkiyatı (hata düzeltme)'");
			EndIf;
	
			If Items.MethodOfReflectingDiscrepanciesAdjustmentByAgreement.ChoiceList.Count() > 0 Then
				Items.MethodOfReflectingDiscrepanciesAdjustmentByAgreement.ChoiceList[0].Presentation =
					NStr("vi = 'Tạo điều chỉnh chứng từ (theo thỏa thuận của các bên)';
						|ru = 'Оформить корректировку документов (по согласованию сторон)';
						|en = 'Register document adjustment (as agreed by the parties)'; fa = 'Register document adjustment (as agreed by the parties)';
						|it = 'Register document adjustment (as agreed by the parties)';
						|pl = 'Register document adjustment (as agreed by the parties)';
						|tr = 'Belge düzeltmesi oluştur (taraflarca mutabık kalındığı üzere)'");
			EndIf;
			
		EndIf;
		
	Else
		
		Items.HowToReflectDiscrepanciesDocumentChanges.Visible       = True;
		Items.MethodForReflectingDiscrepanciesCorrectionCorrection.Visible = False;
		Items.MethodOfReflectingDiscrepanciesAdjustmentByAgreement.Visible = False;

		Items.MethodForReflectingDiscrepanciesAdjustmentNew.Visible       = False;
		Items.GroupInformationAboutAvailabilityOfTheRecordMethod.Visible       = False;
		
	EndIf;

	MethodMismatchMessageRequired = False;
	DetermineNeedForMethodMismatch(Object, AvailableWaysOfProcessingTheCertificate, MethodMismatchMessageRequired);
	
	ExplanationText = ExplanationTextMethodOfWorkingOutActAfterImplementation(Form, MethodMismatchMessageRequired);
	ConfigureFormElementsToReflect(Object, Items, MethodMismatchMessageRequired, ExplanationText);

EndProcedure

Procedure ManagingWayDiscrepanciesAreReflectedShipmentOfItemsToCustomer(Form)
	
	Items = Form.Items;
	
	If Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList.Count() > 0 Then
		Items.HowToReflectDiscrepanciesDocumentChanges.ChoiceList[0].Presentation =
			NStr("vi = 'Thay đổi giao hàng cho khách';
				|ru = 'Изменить отгрузку товаров клиенту';
				|en = 'Change goods shipment to customer'; fa = 'Change goods shipment to customer';
				|it = 'Change goods shipment to customer';
				|pl = 'Change goods shipment to customer';
				|tr = 'Müşteri ürün sevkiyatını değiştir'");
	EndIf;

	If Items.MethodForReflectingDiscrepanciesCorrectionCorrection.ChoiceList.Count() > 0 Then
		Items.MethodForReflectingDiscrepanciesCorrectionCorrection.ChoiceList[0].Presentation =
			NStr("vi = 'Tạo chỉnh sửa giao hàng cho khách';
				|ru = 'Оформить исправление отгрузки товаров клиенту';
				|en = 'Register an adjustment of goods shipment to customer'; fa = 'Register an adjustment of goods shipment to customer';
				|it = 'Register an adjustment of goods shipment to customer';
				|pl = 'Register an adjustment of goods shipment to customer';
				|tr = 'Müşteri ürün sevkiyatı düzeltmesi oluştur'");
	EndIf;

	Items.MethodOfReflectingDiscrepanciesAdjustmentByAgreement.Visible = False;
	Items.MethodForReflectingDiscrepanciesAdjustmentNew.Visible          = False;
	
	ConfigureFormElementsToReflect(Form.Object, Items, False, "");
	
EndProcedure

Function ExplanationTextMethodOfWorkingOutActAfterAcquisition(Form, MethodMismatchMessageRequired)
	
	ExplanationText = "";
	
	If Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Count() = 0 Then
		
		If Form.StatusOfTheEDIBasis = "IsInProcessing" Then
			
			ExplanationText = NStr("vi = 'Chứng từ cơ sở tham gia vào HTTĐVBĐT, nhưng đối tác hiện vẫn chưa từ chối và chưa xác nhận chứng từ.
										|Không thể xử lý các chênh lệch.';
										|ru = 'Документ-основание участвует в ЭДО, но контрагент пока не отклонил и не подтвердил документ.
										|Отработка расхождений недоступна.';
										|en = 'The base document is used in EDI, but the counterparty has neither rejected nor confirmed the document.
										|Discrepancy processing is not available.'; fa = 'The base document is used in EDI, but the counterparty has neither rejected nor confirmed the document.
										|Discrepancy processing is not available.';
										|it = 'The base document is used in EDI, but the counterparty has neither rejected nor confirmed the document.
										|Discrepancy processing is not available.';
										|pl = 'The base document is used in EDI, but the counterparty has neither rejected nor confirmed the document.
										|Discrepancy processing is not available.';
										|tr = 'Elektronik Belge Yönetimi''nde bir temel belge yer almaktadır, ancak cari hesap henüz belgeyi reddetmemiş veya onaylamamıştır.
										|Tutarsızlık çalışması mevcut değildir.'");
			
		EndIf;
		
	ElsIf Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
			PredefinedValue("Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries")) = Undefined 
			And Form.UseDebitNotes Then
			
			ExplanationText = NStr("vi = 'Chứng từ điện tử mua hàng bị từ chối. Chỉ có thể thay đổi dữ liệu tiếp nhận.';
									|ru = 'Электронный документ по приобретению был отклонен. Возможно только изменение поступления.';
									|en = 'Electronic purchase document was rejected. You can only change receipt.'; fa = 'Electronic purchase document was rejected. You can only change receipt.';
									|it = 'Il documento elettronico di acquisto è stato rifiutato.  È  possibile solo la modifica del versamento.';
									|pl = 'Elektroniczny dokument nabycia został odrzucony. Możliwa jest jedynie zmiana przychodów.';
									|tr = 'Elektronik satın alım belgesi reddedildi. Sadece makbuz değişikliği mümkündür.'");
	
	ElsIf Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
		PredefinedValue("Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments")) = Undefined Then
			
		If Not Form.UseDebitNotes  Then
	
			ExplanationText = NStr("vi = 'Đã xác nhận chứng từ điện tử mua sắm. Chỉ có thể điều chỉnh mua sắm,
			                     |nhưng đã vô hiệu hóa việc sử dụng chúng.';
			                     |ru = 'Электронный документ по приобретению подтвержден. Возможна только корректировка приобретения,
			                     |но их использование отключено.';
			                     |en = 'Electronic purchase document is confirmed. You can only create purchase adjustments,
			                     |but cannot use it.'; fa = 'Electronic purchase document is confirmed. You can only create purchase adjustments,
			                     |but cannot use it.';
			                     |it = 'Documento elettronico di acquisto confermato. È  possibile solo correggere l''acquisto,
			                     | ma il loro uso è disabilitato.';
			                     |pl = 'Dokument elektroniczny nabycia został potwierdzony. Możliwe jest tylko korygowanie nabycia,
			                     |ale ich użycie jest wyłączone.';
			                     |tr = 'Elektronik satın alım belgesi onaylanmıştır. Yalnızca satın alma düzeltmesi mümkündür, 
			                     |ancak bunların kullanımı devre dışı bırakılmıştır.'");
			                             
		Else
			
			ExplanationText = NStr("vi = 'Chứng từ mua hàng điện tử xác nhận. Chỉ có thể điều chỉnh mua hàng.';
									|ru = 'Электронный документ по приобретению подтвержден. Возможна только корректировка приобретения.';
									|en = 'Electronic purchase document is confirmed. You can only create purchase adjustments.'; fa = 'Electronic purchase document is confirmed. You can only create purchase adjustments.';
									|it = 'Documento elettronico di acquisto confermato. È  possibile solo correggere l''acquisto.';
									|pl = 'Dokument elektroniczny nabycia jest potwierdzony. Możliwe jest tylko korygowanie nabycia.';
									|tr = 'Elektronik satın alım belgesi onaylanmıştır. Sadece satın alma düzeltmesi mümkündür.'");
			
		EndIf;
		
	EndIf;
	
	If MethodMismatchMessageRequired Then
		
		MethodMismatchMessage = NStr("vi = 'Phương pháp phản ánh hiện tại không chính xác. Bạn có thể thay đổi nó trong trạng thái ""Không đồng ý"" hoặc ""Được cung cấp""';
									|ru = 'Текущий способ отражения некорректен. Изменить его можно в статусе ""Не согласовано"" или ""Обеспечивается""';
									|en = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status'; fa = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status';
									|it = 'Il metodo corrente di riflessione è errato. È possibile modificarlo nello stato ""non approvato"" o ""in approvazione""';
									|pl = 'Aktualna metoda odbicia jest nieprawidłowa. Możesz zmienić go na status „Nie uzgodniono” lub „Dostarczone”';
									|tr = 'Mevcut gösterim yöntemi yanlıştır. Bunu ""Kabul edilmedi"" veya ""Güvence altına alındı"" durumuna değiştirebilirsiniz'");
		
		ExplanationText = ExplanationText + Chars.LF + MethodMismatchMessage;
	
	EndIf;

	Return ExplanationText;

EndFunction

Function ExplanationTextMethodOfWorkingOutActAfterImplementation(Form, MethodMismatchMessageRequired)

	ExplanationText = "";

	If Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Count() = 0 Then
			
		If (Form.StatusOfTheEDIBasis = "IsInProcessing"
			Or Form.StatusOfTheEDIBasis = "Received"
			Or Form.StatusOfTheEDIBasis = "DeviationInProcessing"
			Or Form.StatusOfTheEDIBasis = "ApprovalInProcessing")Then
		
			ExplanationText = NStr("vi = 'Chứng từ cơ sở tham gia vào HTTĐVBĐT, nhưng khách hàng hiện vẫn chưa từ chối và chưa xác nhận chứng từ.
			                             |Không thể xử lý các chênh lệch.';
			                             |ru = 'Документ-основание участвует в ЭДО, но покупатель пока не отклонил и не подтвердил документ.
			                             |Отработка расхождений недоступна.';
			                             |en = 'The base document is used in EDI, but the customer has neither rejected nor confirmed the document.
			                             |Discrepancy processing is not available.'; fa = 'The base document is used in EDI, but the customer has neither rejected nor confirmed the document.
			                             |Discrepancy processing is not available.';
			                             |it = 'The base document is used in EDI, but the customer has neither rejected nor confirmed the document.
			                             |Discrepancy processing is not available.';
			                             |pl = 'The base document is used in EDI, but the customer has neither rejected nor confirmed the document.
			                             |Discrepancy processing is not available.';
			                             |tr = 'Elektronik Belge Yönetimi''nde bir temel belge yer almaktadır, ancak müşteri hesap henüz belgeyi reddetmemiş veya onaylamamıştır.
			                             |Tutarsızlık çalışması mevcut değildir.'");
		
		EndIf;
			
	ElsIf Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")) = Undefined Then
				
		If Not Form.UseCreditNotes  Then
	
			ExplanationText = NStr("vi = 'Người mua đã xác nhận chứng từ bán hàng điện tử. Chỉ có thể điều chỉnh bán hàng,
			                             |nhưng việc sử dụng chúng đã bị vô hiệu hóa.';
			                             |ru = 'Электронный документ по реализации подтвержден покупателем. Возможна только корректировка реализации,
			                             |но их использование отключено.';
			                             |en = 'Electronic sale document is confirmed by the customer. You can create sales adjustments for it,
			                             |but cannot use it.'; fa = 'Electronic sale document is confirmed by the customer. You can create sales adjustments for it,
			                             |but cannot use it.';
			                             |it = 'Il documento elettronico di vendita è stato confermato dall''acquirente. È possibile solo la correzione della vendita, 
			                             | ma il suo utilizzo è disabilitato.';
			                             |pl = 'Dokument elektroniczny realizacji jest potwierdzony przez kupującego. Możliwe jest korygowanie realizacji,
			                             |ale ich użycie jest wyłączone.';
			                             |tr = 'Elektronik satış belgesi alıcı tarafından onaylandı. Yalnızca satış düzeltmesi mümkündür,
			                             | ancak bunların kullanımı devre dışı bırakılmıştır.'");
			                             
		Else
			
			ExplanationText = NStr("vi = 'Một chứng từ bán hàng điện tử được xác nhận bởi người mua. Chỉ có thể điều chỉnh việc thực hiện.';
									|ru = 'Электронный документ по реализации подтвержден покупателем. Возможна только корректировка реализации.';
									|en = 'An electronic sales document is confirmed by the customer. You can only create sales adjustments for it.'; fa = 'An electronic sales document is confirmed by the customer. You can only create sales adjustments for it.';
									|it = 'Il documento elettronico di vendita è stato confermato dall''acquirente. È possibile solo la correzione della vendita.';
									|pl = 'Dokument elektroniczny realizacji jest potwierdzony przez kupującego. Jest możliwe tylko korygowanie realizacji.';
									|tr = 'Elektronik satış belgesi alıcı tarafından onaylandı. Yalnızca satış düzeltmesi mümkündür.'");
			
		EndIf;
		
	ElsIf Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection")) = Undefined 
			And Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
				PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments")) = Undefined 
			And Form.UseCreditNotes Then
				
			ExplanationText = NStr("vi = 'Chứng từ bán hàng điện tử bị từ chối bởi người mua. Chỉ có thể thay đổi dữ liệu giao hàng.';
									|ru = 'Электронный документ по реализации отклонен покупателем. Возможно только изменение реализации.';
									|en = 'Electronic purchase document is rejected by the customer. You can only change implementation.'; fa = 'Electronic purchase document is rejected by the customer. You can only change implementation.';
									|it = 'Il documento elettronico di vendita rifiutato dall''acquirente.  È possibile solo la correzione della vendita.';
									|pl = 'Elektroniczny dokument sprzedaży odrzucony przez kupującego. Możliwa jest jedynie zmiana implementacji.';
									|tr = 'Elektronik satış belgesi alıcı tarafından reddedilmiştir. Sadece satışta değişiklik yapmak mümkündür.'");
		
	EndIf;
	
	If MethodMismatchMessageRequired Then
		
		MethodMismatchMessage = NStr("vi = 'Phương pháp phản ánh hiện tại không chính xác. Bạn có thể thay đổi nó trong trạng thái ""Không đồng ý"" hoặc ""Được cung cấp""';
									|ru = 'Текущий способ отражения некорректен. Изменить его можно в статусе ""Не согласовано"" или ""Обеспечивается""';
									|en = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status'; fa = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status';
									|it = 'Il metodo corrente di riflessione è errato. È possibile modificarlo nello stato ""non approvato"" o ""in approvazione""';
									|pl = 'Aktualna metoda odbicia jest nieprawidłowa. Możesz zmienić go na status „Nie uzgodniono” lub „Dostarczone”';
									|tr = 'Mevcut gösterim yöntemi yanlıştır. Bunu ""Kabul edilmedi"" veya ""Güvence altına alındı"" durumuna değiştirebilirsiniz'");
		
		ExplanationText = ExplanationText + Chars.LF + MethodMismatchMessage;
	
	EndIf;

	Return ExplanationText;

EndFunction

Function ExplanationTextMethodOfWorkingOutActAfterTransfer(Form, MethodMismatchMessageRequired)
	
	ExplanationText = "";
	FixIsAvailable = Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
		PredefinedValue(
			"Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection")) <> Undefined;
	
	If Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Count() = 0 Then
		
		If (Form.StatusOfTheEDIBasis = "IsInProcessing"
			Or Form.StatusOfTheEDIBasis = "Received"
			Or Form.StatusOfTheEDIBasis = "DeviationInProcessing"
			Or Form.StatusOfTheEDIBasis = "ApprovalInProcessing") Then
			
			ExplanationText = NStr("vi = 'Chứng từ cơ sở tham gia vào HTTĐVBĐT. Để xử lý chênh lệch, cần ký hoặc hủy chứng từ.';
									|ru = 'Документ-основание участвует в ЭДО. Для отработки расхождений нужно подписать или отклонить документ.';
									|en = 'The base document is used in EDI. To process discrepancies, sign or reject the document.'; fa = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|it = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|pl = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|tr = 'Ana belge, Elektronik Belge Yönetimi''nde bulunur. Uyuşmazlıkları çözmek için belgeyi imzalamak veya reddetmek gerekmektedir.'");
			
		EndIf;
		
	ElsIf Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
		PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")) = Undefined Then
		
		ExplanationText = NStr("vi = 'Đã xác nhận chứng từ chuyển giao. Chỉ có thể chỉnh sửa chuyển giao.';
								|ru = 'Электронный документ по передаче подтвержден. Возможно только исправление передачи.';
								|en = 'The electronic transfer document is confirmed. You can only adjust the transfer.'; fa = 'The electronic transfer document is confirmed. You can only adjust the transfer.';
								|it = 'The electronic transfer document is confirmed. You can only adjust the transfer.';
								|pl = 'The electronic transfer document is confirmed. You can only adjust the transfer.';
								|tr = 'Elektronik aktarım belgesi onaylandı. Sadece yama düzeltilebilir.'");
		
	ElsIf Not FixIsAvailable Then
			ExplanationText = NStr("vi = 'Chứng từ điện tử chuyển giao đã bị từ chối. Chỉ có thể thay đổi dữ liệu chuyển giao.';
									|ru = 'Электронный документ по передаче был отклонен. Возможно только изменение передачи.';
									|en = 'The electronic transfer document is rejected. You can only edit the transfer.'; fa = 'The electronic transfer document is rejected. You can only edit the transfer.';
									|it = 'The electronic transfer document is rejected. You can only edit the transfer.';
									|pl = 'The electronic transfer document is rejected. You can only edit the transfer.';
									|tr = 'Elektronik aktarım belgesi reddedildi. Sadece değişiklik  düzeltilebilir.'");
	EndIf;
	
	If FixIsAvailable And Not Form.UseDocumentCorrection Then
		MessageAboutImpossibilityOfUsingCorrection =
			NStr("vi = 'Để thực hiện chỉnh sửa bằng một chứng từ riêng, hãy kích hoạt tùy chọn chức năng ""Chỉnh sửa và đảo ngược chứng từ tài chính""';
				|ru = 'Для того чтобы оформить исправление отдельным документом, включите функциональную опцию ""Исправление и сторно финансовых документов""';
				|en = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option'; fa = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
				|it = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
				|pl = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
				|tr = 'Yamayı ayrı bir belge halinde düzenlemek için ""Finansal belgelerin düzeltilmesi ve iptali"" fonksiyon seçeneğini etkinleştirin'");
		If IsBlankString(ExplanationText) Then
			ExplanationText = MessageAboutImpossibilityOfUsingCorrection;
		Else
			ExplanationText = ExplanationText + Chars.LF + MessageAboutImpossibilityOfUsingCorrection;
		EndIf;
	EndIf;
	
	If MethodMismatchMessageRequired Then
		MethodMismatchMessage = NStr("vi = 'Phương pháp phản ánh hiện tại không chính xác. Bạn có thể thay đổi nó trong trạng thái ""Không thống nhất"" hoặc ""Được đảm bảo""';
									|ru = 'Текущий способ отражения некорректен. Изменить его можно в статусе ""Не согласовано"" или ""Обеспечивается""';
									|en = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status'; fa = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status';
									|it = 'Il metodo corrente di riflessione è errato. È possibile modificarlo nello stato ""non approvato"" o ""in approvazione""';
									|pl = 'Aktualna metoda odbicia jest nieprawidłowa. Możesz zmienić go na status „Nie uzgodniono” lub „Dostarczone”';
									|tr = 'Mevcut gösterim yöntemi yanlıştır. Bunu ""Kabul edilmedi"" veya ""Güvence altına alındı"" durumuna değiştirebilirsiniz'");
		ExplanationText = ExplanationText + Chars.LF + MethodMismatchMessage;
	EndIf;
	
	Return ExplanationText;
	
EndFunction

Function ExplanationTextMethodOfWorkingOutActAfterShipment(Form, MethodMismatchMessageRequired)
	
	ExplanationText = "";
	FixIsAvailable = Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
		PredefinedValue(
			"Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection")) <> Undefined;
	
	If Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Count() = 0 Then
		
		If (Form.StatusOfTheEDIBasis = "IsInProcessing"
			Or Form.StatusOfTheEDIBasis = "Received"
			Or Form.StatusOfTheEDIBasis = "DeviationInProcessing"
			Or Form.StatusOfTheEDIBasis = "ApprovalInProcessing") Then
			
			ExplanationText = NStr("vi = 'Chứng từ cơ sở tham gia vào HTTĐVBĐT. Để xử lý chênh lệch, cần ký hoặc hủy chứng từ.';
									|ru = 'Документ-основание участвует в ЭДО. Для отработки расхождений нужно подписать или отклонить документ.';
									|en = 'The base document is used in EDI. To process discrepancies, sign or reject the document.'; fa = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|it = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|pl = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|tr = 'Ana belge, Elektronik Belge Yönetimi''nde bulunur. Uyuşmazlıkları çözmek için belgeyi imzalamak veya reddetmek gerekmektedir.'");
			
		EndIf;
		
	ElsIf Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
		PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments")) = Undefined Then
		
		If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage") Then
			ExplanationText = NStr("vi = 'Đã xác nhận chứng từ điện tử giao hàng. Chỉ có thể chỉnh sửa dữ liệu giao hàng.';
									|ru = 'Электронный документ по отгрузке подтвержден. Возможно только исправление отгрузки.';
									|en = 'The electronic shipment document is confirmed. You can only adjust the shipment.'; fa = 'The electronic shipment document is confirmed. You can only adjust the shipment.';
									|it = 'The electronic shipment document is confirmed. You can only adjust the shipment.';
									|pl = 'The electronic shipment document is confirmed. You can only adjust the shipment.';
									|tr = 'Sevkiyata ilişkin elektronik belge onaylandı. Sadece sevkiyatın yaması düzeltilebilir.'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider") Then
			ExplanationText = NStr("vi = 'Đã xác nhận chứng từ chuyển giao cho bên đặt gia công. Chỉ có thể chỉnh sửa chuyển giao.';
									|ru = 'Электронный документ по передаче давальцу подтвержден. Возможно только исправление передачи.';
									|en = 'The electronic document on transfer to material provider is confirmed. You can only adjust the transfer.'; fa = 'The electronic document on transfer to material provider is confirmed. You can only adjust the transfer.';
									|it = 'The electronic document on transfer to material provider is confirmed. You can only adjust the transfer.';
									|pl = 'The electronic document on transfer to material provider is confirmed. You can only adjust the transfer.';
									|tr = 'Sağlayıcıya elektronik aktarım belgesi onaylandı. Sadece yama düzeltilebilir.'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider") Then
			ExplanationText = NStr("vi = 'Đã xác nhận chứng từ điện tử trả lại cho bên đặt gia công. Chỉ có thể chỉnh sửa dữ liệu trả lại.';
									|ru = 'Электронный документ по возврату давальцу подтвержден. Возможно только исправление возврата.';
									|en = 'The electronic Goods return — Subcontracting services delivered is confirmed. You can only adjust the return.'; fa = 'The electronic Goods return — Subcontracting services delivered is confirmed. You can only adjust the return.';
									|it = 'The electronic Goods return — Subcontracting services delivered is confirmed. You can only adjust the return.';
									|pl = 'The electronic Goods return — Subcontracting services delivered is confirmed. You can only adjust the return.';
									|tr = 'Sağlayıcıya iade elektronik belgesi onaylandı. Sadece iade düzeltilebilir.'");
		EndIf;
		
	ElsIf Not FixIsAvailable Then
		
		If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage") Then
			ExplanationText = NStr("vi = 'Chứng từ điện tử giao hàng đã bị từ chối. Chỉ có thể thay đổi dữ liệu giao hàng.';
									|ru = 'Электронный документ по отгрузке был отклонен. Возможно только изменение отгрузки.';
									|en = 'The electronic shipment document is rejected. You can only edit the shipment.'; fa = 'The electronic shipment document is rejected. You can only edit the shipment.';
									|it = 'The electronic shipment document is rejected. You can only edit the shipment.';
									|pl = 'The electronic shipment document is rejected. You can only edit the shipment.';
									|tr = 'Elektronik sevkiyat belgesi reddedildi. Sadece sevkiyat değiştirilebilir.'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider") Then
			ExplanationText = NStr("vi = 'Chứng từ điện tử chuyển giao cho bên đặt gia công đã bị từ chối. Chỉ có thể thay đổi dữ liệu chuyển giao.';
									|ru = 'Электронный документ по передаче давальцу был отклонен. Возможно только изменение передачи.';
									|en = 'The electronic document on transfer to material provider is rejected. You can only edit the transfer.'; fa = 'The electronic document on transfer to material provider is rejected. You can only edit the transfer.';
									|it = 'The electronic document on transfer to material provider is rejected. You can only edit the transfer.';
									|pl = 'The electronic document on transfer to material provider is rejected. You can only edit the transfer.';
									|tr = 'Sağlayıcıya yapılan havaleyle ilgili elektronik belge reddedildi. Sadece transfer değiştirilebilir.'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider") Then
			ExplanationText = NStr("vi = 'Chứng từ điện tử trả lại cho bên đặt gia công đã bị từ chối. Chỉ có thể thay đổi dữ liệu trả lại.';
									|ru = 'Электронный документ по возврату давальцу был отклонен. Возможно только изменение возврата.';
									|en = 'The electronic Goods return — Subcontracting services delivered is rejected. You can only edit the return.'; fa = 'The electronic Goods return — Subcontracting services delivered is rejected. You can only edit the return.';
									|it = 'The electronic Goods return — Subcontracting services delivered is rejected. You can only edit the return.';
									|pl = 'The electronic Goods return — Subcontracting services delivered is rejected. You can only edit the return.';
									|tr = 'Sağlayıcıdan iadeye yönelik elektronik kabul belgesi reddedildi. Sadece iade değiştirilebilir.'");
		EndIf;
		
	EndIf;
	
	If FixIsAvailable And Not Form.UseDocumentCorrection Then
		MessageAboutImpossibilityOfUsingCorrection
			= NStr("vi = 'Để thực hiện chỉnh sửa bằng một chứng từ riêng, hãy kích hoạt tùy chọn chức năng ""Chỉnh sửa và đảo ngược chứng từ tài chính""';
					|ru = 'Для того чтобы оформить исправление отдельным документом, включите функциональную опцию ""Исправление и сторно финансовых документов""';
					|en = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option'; fa = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
					|it = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
					|pl = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
					|tr = 'Yamayı ayrı bir belge halinde düzenlemek için ""Finansal belgelerin düzeltilmesi ve iptali"" fonksiyon seçeneğini etkinleştirin'");
		If IsBlankString(ExplanationText) Then
			ExplanationText = MessageAboutImpossibilityOfUsingCorrection;
		Else
			ExplanationText = ExplanationText + Chars.LF + MessageAboutImpossibilityOfUsingCorrection;
		EndIf;
	EndIf;
	
	If MethodMismatchMessageRequired Then
		MethodMismatchMessage = NStr("vi = 'Phương pháp phản ánh hiện tại không chính xác. Bạn có thể thay đổi nó trong trạng thái ""Không thống nhất"" hoặc ""Được đảm bảo""';
									|ru = 'Текущий способ отражения некорректен. Изменить его можно в статусе ""Не согласовано"" или ""Обеспечивается""';
									|en = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status'; fa = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status';
									|it = 'Il metodo corrente di riflessione è errato. È possibile modificarlo nello stato ""non approvato"" o ""in approvazione""';
									|pl = 'Aktualna metoda odbicia jest nieprawidłowa. Możesz zmienić go na status „Nie uzgodniono” lub „Dostarczone”';
									|tr = 'Mevcut gösterim yöntemi yanlıştır. Bunu ""Kabul edilmedi"" veya ""Güvence altına alındı"" durumuna değiştirebilirsiniz'");
		ExplanationText = ExplanationText + Chars.LF + MethodMismatchMessage;
	EndIf;
	
	Return ExplanationText;
	
EndFunction

Function ExplanationTextMethodOfWorkingOutActAfterAcceptanceAndReceipt(Form, MethodMismatchMessageRequired)
	
	ExplanationText = "";
	FixIsAvailable = Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
		PredefinedValue(
			"Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries")) <> Undefined;
	
	If Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Count() = 0 Then
		
		If (Form.StatusOfTheEDIBasis = "IsInProcessing"
			Or Form.StatusOfTheEDIBasis = "Received"
			Or Form.StatusOfTheEDIBasis = "DeviationInProcessing"
			Or Form.StatusOfTheEDIBasis = "ApprovalInProcessing") Then
			
			ExplanationText = NStr("vi = 'Chứng từ cơ sở tham gia vào HTTĐVBĐT. Để xử lý chênh lệch, cần ký hoặc hủy chứng từ.';
									|ru = 'Документ-основание участвует в ЭДО. Для отработки расхождений нужно подписать или отклонить документ.';
									|en = 'The base document is used in EDI. To process discrepancies, sign or reject the document.'; fa = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|it = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|pl = 'The base document is used in EDI. To process discrepancies, sign or reject the document.';
									|tr = 'Ana belge, Elektronik Belge Yönetimi''nde bulunur. Uyuşmazlıkları çözmek için belgeyi imzalamak veya reddetmek gerekmektedir.'");
			
		EndIf;
		
	ElsIf Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.FindByValue(
		PredefinedValue("Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments")) = Undefined Then
		
		If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
			ExplanationText = NStr("vi = 'Đã xác nhận chứng từ điện tử nhập hàng. Chỉ có thể chỉnh sửa dữ liệu nhập hàng.';
									|ru = 'Электронный документ по приемке подтвержден. Возможно только исправление приемки.';
									|en = 'The electronic receipt document is confirmed. You can only adjust the receipt.'; fa = 'The electronic receipt document is confirmed. You can only adjust the receipt.';
									|it = 'The electronic receipt document is confirmed. You can only adjust the receipt.';
									|pl = 'The electronic receipt document is confirmed. You can only adjust the receipt.';
									|tr = 'Elektronik kabul belgesi onaylandı. Sadece kabul düzeltilebilir.'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor") Then
			ExplanationText = NStr("vi = 'Đã xác nhận chứng từ điện tử nhận trả lại nguyên vật liệu từ bên nhận gia công. Chỉ có thể chỉnh sửa dữ liệu trả lại.';
									|ru = 'Электронный документ по возврату сырья от переработчика подтвержден. Возможно только исправление возврата.';
									|en = 'The electronic document on return of raw materials from subcontractor is confirmed. You can only adjust the return.'; fa = 'The electronic document on return of raw materials from subcontractor is confirmed. You can only adjust the return.';
									|it = 'The electronic document on return of raw materials from subcontractor is confirmed. You can only adjust the return.';
									|pl = 'The electronic document on return of raw materials from subcontractor is confirmed. You can only adjust the return.';
									|tr = 'Hammaddelerin fason üreticiden iadesi için elektronik belge onaylandı. Sadece iade düzeltilebilir.'");
		Else
			ExplanationText = NStr("vi = 'Đã xác nhận chứng từ điện tử nhập hàng. Chỉ có thể chỉnh sửa dữ liệu nhập hàng.';
									|ru = 'Электронный документ по приемке подтвержден. Возможно только исправление приемки.';
									|en = 'The electronic receipt document is confirmed. You can only adjust the receipt.'; fa = 'The electronic receipt document is confirmed. You can only adjust the receipt.';
									|it = 'The electronic receipt document is confirmed. You can only adjust the receipt.';
									|pl = 'The electronic receipt document is confirmed. You can only adjust the receipt.';
									|tr = 'Elektronik kabul belgesi onaylandı. Sadece kabul düzeltilebilir.'");
		EndIf;
		
	ElsIf Not FixIsAvailable Then
		
		If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
			ExplanationText = NStr("vi = 'Đã từ chối chứng từ điện tử nhập hàng. Chỉ có thể chỉnh sửa dữ liệu nhập hàng.';
									|ru = 'Электронный документ по приемке был отклонен. Возможно только изменение приемки.';
									|en = 'The electronic receipt document is rejected. You can only edit the receipt.'; fa = 'The electronic receipt document is rejected. You can only edit the receipt.';
									|it = 'The electronic receipt document is rejected. You can only edit the receipt.';
									|pl = 'The electronic receipt document is rejected. You can only edit the receipt.';
									|tr = 'Elektronik kabul belgesi reddedildi. Sadece kabul değiştirilebilir.'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor") Then
			ExplanationText = NStr("vi = 'Chứng từ điện tử nhận trả lại nguyên vật liệu từ bên nhận gia công đã bị từ chối. Chỉ có thể thay đổi dữ liệu trả lại.';
									|ru = 'Электронный документ по возврату сырья от переработчика был отклонен. Возможно только изменение возврата.';
									|en = 'The electronic document on return of raw materials from subcontractor is rejected. You can only edit the return.'; fa = 'The electronic document on return of raw materials from subcontractor is rejected. You can only edit the return.';
									|it = 'The electronic document on return of raw materials from subcontractor is rejected. You can only edit the return.';
									|pl = 'The electronic document on return of raw materials from subcontractor is rejected. You can only edit the return.';
									|tr = 'Fason üreticiden hammadde iadesine yönelik elektronik kabul belgesi reddedildi. Sadece iade değiştirilebilir.'");
		Else
			ExplanationText = NStr("vi = 'Đã từ chối chứng từ điện tử nhập hàng. Chỉ có thể chỉnh sửa dữ liệu nhập hàng.';
									|ru = 'Электронный документ по приемке был отклонен. Возможно только изменение приемки.';
									|en = 'The electronic receipt document is rejected. You can only edit the receipt.'; fa = 'The electronic receipt document is rejected. You can only edit the receipt.';
									|it = 'The electronic receipt document is rejected. You can only edit the receipt.';
									|pl = 'The electronic receipt document is rejected. You can only edit the receipt.';
									|tr = 'Elektronik kabul belgesi reddedildi. Sadece kabul değiştirilebilir.'");
		EndIf;
		
	EndIf;
	
	If FixIsAvailable And Not Form.UseDocumentCorrection Then
		MessageAboutImpossibilityOfUsingCorrection =
			NStr("vi = 'Để thực hiện chỉnh sửa bằng một chứng từ riêng, hãy kích hoạt tùy chọn chức năng ""Chỉnh sửa và đảo ngược chứng từ tài chính""';
				|ru = 'Для того чтобы оформить исправление отдельным документом, включите функциональную опцию ""Исправление и сторно финансовых документов""';
				|en = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option'; fa = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
				|it = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
				|pl = 'To issue a correction as a separate document, enable the ""Financial document correction and storno"" functional option';
				|tr = 'Yamayı ayrı bir belge halinde düzenlemek için ""Finansal belgelerin düzeltilmesi ve iptali"" fonksiyon seçeneğini etkinleştirin'");
		If IsBlankString(ExplanationText) Then
			ExplanationText = MessageAboutImpossibilityOfUsingCorrection;
		Else
			ExplanationText = ExplanationText + Chars.LF + MessageAboutImpossibilityOfUsingCorrection;
		EndIf;
	EndIf;
	
	If MethodMismatchMessageRequired Then
		MethodMismatchMessage = NStr("vi = 'Phương pháp phản ánh hiện tại không chính xác. Bạn có thể thay đổi nó trong trạng thái ""Không thống nhất"" hoặc ""Được đảm bảo""';
									|ru = 'Текущий способ отражения некорректен. Изменить его можно в статусе ""Не согласовано"" или ""Обеспечивается""';
									|en = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status'; fa = 'The current record method is incorrect. You can change it in the ""Not approved"" or the ""Supplied"" status';
									|it = 'Il metodo corrente di riflessione è errato. È possibile modificarlo nello stato ""non approvato"" o ""in approvazione""';
									|pl = 'Aktualna metoda odbicia jest nieprawidłowa. Możesz zmienić go na status „Nie uzgodniono” lub „Dostarczone”';
									|tr = 'Mevcut gösterim yöntemi yanlıştır. Bunu ""Kabul edilmedi"" veya ""Güvence altına alındı"" durumuna değiştirebilirsiniz'");
		ExplanationText = ExplanationText + Chars.LF + MethodMismatchMessage;
	EndIf;
	
	Return ExplanationText;
	
EndFunction

Procedure FillInDocumentBaseInLine(RowOfProductsTable, BasisDocuments) Export

	If Not RowOfProductsTable.FilledUsingBaseDocument And Not ValueIsFilled(RowOfProductsTable.DocumentBasis) Then
		If BasisDocuments.Count() = 1 Then
			RowOfProductsTable.DocumentBasis = BasisDocuments[0].DocumentBasis;
			SetBasedOnOrdersAttribute(RowOfProductsTable, BasisDocuments[0]);
			FillInOrderInLine(RowOfProductsTable, BasisDocuments);
		EndIf;
	EndIf;

EndProcedure

Procedure FillInOrderInLine(RowOfProductsTable, BasisDocuments) Export

	FoundRows = BasisDocuments.FindRows(New Structure("DocumentBasis", RowOfProductsTable.DocumentBasis));
	If FoundRows.Count() = 0 Then
		Return;
	EndIf;

	FoundRow = FoundRows[0];

	If Not ValueIsFilled(RowOfProductsTable.OrderDocument) Then
		If FoundRow.BasisOrders.Count() = 1 Then
			RowOfProductsTable.OrderDocument = FoundRow.BasisOrders.Get(0).Value;
		EndIf;
	EndIf;

EndProcedure

Procedure SetBasedOnOrdersAttribute(RowOfProductsTable, StringFoundationDocuments) Export
	
	RowOfProductsTable.BasisByOrders = (StringFoundationDocuments.BasisOrders.Count() > 0);
	
EndProcedure

Procedure SetDynamicListStatusSelection(DynamicList, StatusForSelection) Export
	
	SelectionIsEstablished = ValueIsFilled(StatusForSelection);
	
	CommonClientServer.SetDynamicListFilterItem(DynamicList, 
	                                                                        "Status",
	                                                                        StatusForSelection, 
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        ,
	                                                                        SelectionIsEstablished);
	
	CommonClientServer.SetDynamicListFilterItem(DynamicList, 
	                                                                        "Posted",
	                                                                        True, 
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        ,
	                                                                        SelectionIsEstablished);
	
EndProcedure

Procedure FillInTransactionInLine(CurrentData, TransactionOrders) Export

	If CurrentData.BasisByOrders And ValueIsFilled(CurrentData.PurchaseOrder) Then
		
		FoundRows = TransactionOrders.FindRows(New Structure("PurchaseOrder", CurrentData.PurchaseOrder));
		If FoundRows.Count() > 0 Then
			CurrentData.SalesOpportunity = FoundRows[0].SalesOpportunity;
			Return;
		EndIf;
	
	EndIf;
	
	CurrentData.SalesOpportunity = PredefinedValue("Catalog.SalesOpportunitiesToCustomer.EmptyRef");
	
EndProcedure

Function NamesOfDetailsDependingOnTypeOfAct(ThisIsActOfDiscrepanciesAfterShipment) Export
	
	NamesStructure = New Structure;
	NamesStructure.Insert("FilledUsingBaseDocument", ?(ThisIsActOfDiscrepanciesAfterShipment,"FilledInBySale","FilledUsingBaseDocument"));
	NamesStructure.Insert("Basis", ?(ThisIsActOfDiscrepanciesAfterShipment,"SaleOfGoodsAndServices","DocumentBasis"));
	NamesStructure.Insert("OrderDocument", ?(ThisIsActOfDiscrepanciesAfterShipment,"SalesOrder","PurchaseOrder"));
	NamesStructure.Insert("BasisByOrders", ?(ThisIsActOfDiscrepanciesAfterShipment,"OrderSales","BasisByOrders"));
	
	Return NamesStructure;
	
EndFunction

// The procedure calculates the totals of the Form.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the document of the Act of discrepancies
//
Procedure CalculateFormTotals(Form) Export
	
	Form.Shortages = 0;
	Form.Surpluses   = 0;
	Form.ShortfallsVATAmount = 0;
	Form.ExcessVATAmount   = 0;
	Form.ThereAreSurpluses     = False;
	Form.ThereIsShortages   = False;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form.Object, "BusinessOperation")
		And Form.Object.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.GoodsShipmentToCustomer") Then
		
		DisplayTotalAmountOfVAT = False;
		
	Else
		
		DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(
			Form.Object.VATTaxation);
		
	EndIf;
	
	For Each LineProducts_ In Form.Object.Goods Do
		
		If DisplayTotalAmountOfVAT Then
			If LineProducts_.TheAmountOfTheSNDSRansmission > 0 Then
				Form.Surpluses = Form.Surpluses + LineProducts_.TheAmountOfTheSNDSRansmission;
				Form.ExcessVATAmount = Form.ExcessVATAmount + LineProducts_.PersonalIncomeTaxExpense;
			ElsIf LineProducts_.TheAmountOfTheSNDSRansmission < 0 Then
				Form.Shortages = Form.Shortages + (-LineProducts_.TheAmountOfTheSNDSRansmission);
				Form.ShortfallsVATAmount = Form.ShortfallsVATAmount + (-LineProducts_.PersonalIncomeTaxExpense);
			EndIf;
		Else
			If LineProducts_.DiscrepancyAmount > 0 Then
				Form.Surpluses = Form.Surpluses + LineProducts_.DiscrepancyAmount;
			ElsIf LineProducts_.DiscrepancyAmount < 0 Then
				Form.Shortages = Form.Shortages + (-LineProducts_.DiscrepancyAmount);
			EndIf;
		EndIf;
		
		If LineProducts_.NumberOfDiscrepancyPackaging < 0 Then
			Form.ThereIsShortages = True;
		EndIf;
		If LineProducts_.NumberOfDiscrepancyPackaging > 0 Then
			Form.ThereAreSurpluses = True;
		EndIf;
		
	EndDo;
	
	If DisplayTotalAmountOfVAT Then
		Form.Discrepancies = Form.Object.Goods.Total("AmountIncludingVAT") - Form.Object.Goods.Total("AmountIncludingVATByDocument");
		Form.DiscrepanciesVATAmount = Form.Object.Goods.Total("VATAmount") - Form.Object.Goods.Total("VATAmountByDocument");
	Else
		Form.Discrepancies = Form.Object.Goods.Total("Sum") - Form.Object.Goods.Total("SumByDocument");
	EndIf;
	
	Form.Items.TotalsGroupExcludingVAT.Visible = Not DisplayTotalAmountOfVAT;
	Form.Items.GroupResultsWithVAT.Visible = DisplayTotalAmountOfVAT;
	
EndProcedure

Function ThisIsActOfDiscrepanciesAfterShipment(TypeOfBaseDocumentForNonConformanceCertificate) Export
	
	Return TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBaseDocumentForNonConformanceCertificate =
					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
		Or TypeOfBaseDocumentForNonConformanceCertificate =
					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider")
		Or TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate);
	
EndFunction

// Change the action in the row.
// 
// Parameters:
// 	A string - a string of value tables - contains, among other things:
// 		* Action - Enumerationlink.Action variationsreferences after the upload, listing the link.Action variationsreferences from the Acceptance -
// 	actiondocumentdocumentdocumentation - Enumeration link.Action variationsreferences after the upload - 
// 	actiondocumentsreferences - Link enumeration.Action variationsreferences after the upload -
// 	actionestovaromneedback - Enumeration link.Options for the actions of the product after the upload -
// 	ActionesTOvaromiZlishki - Listing link.Options for the actions of the product after the load -
// 	Povinestorny Company - Boolean -

// 
// Returns:
//  Boolean - Change an action in a row
Function ChangeActionInLine(
	String,
	ActionWithShortageDocument,
	ActionWithSurplusDocument,
	ActionWithShortageGoods = Undefined,
	ActionWithSurplusGoods = Undefined,
	ThirdPartyIsGuilty = Undefined) Export
	
	If ValueIsFilled(ActionWithShortageDocument)
		And String.NumberOfDiscrepancyPackaging < 0 Then
		ActionWithDocument = ActionWithShortageDocument;
	Else
		ActionWithDocument = ActionWithSurplusDocument;
	EndIf;
	
	If ValueIsFilled(ActionWithShortageGoods)
		And String.NumberOfDiscrepancyPackaging < 0 Then
		DiscrepancyTreatment = ActionWithShortageGoods;
	ElsIf ValueIsFilled(ActionWithSurplusGoods) Then
		DiscrepancyTreatment = ActionWithSurplusGoods;
	EndIf;
	
	ThereArePropsDueToFaultOfThirdPartyCompany = ThirdPartyIsGuilty <> Undefined;
	ThereIsActionAttributeWithGoods =
		(ActionWithShortageGoods <> Undefined)
			Or (ActionWithSurplusGoods <> Undefined);
	
	If String.Action = ActionWithDocument
		And (Not ThereIsActionAttributeWithGoods
			Or String.DiscrepancyTreatment = DiscrepancyTreatment) Then
		
		If ThereArePropsDueToFaultOfThirdPartyCompany Then
			If String.ThirdPartyIsGuilty = ThirdPartyIsGuilty Then
				Return False;
			EndIf;
		Else
			Return False;
		EndIf;
		
	EndIf;
	
	If ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered")
		Or DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit") Then
		
		If Not String.NumberOfDiscrepancyPackaging > 0 Then
			Return False;
		EndIf;
		
	ElsIf ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses")
		Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices")
		Or DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off")
		Or DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit")
		Or DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_")
		Or DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait") Then
		
		If Not String.NumberOfDiscrepancyPackaging < 0 Then
			Return False;
		EndIf;
		
	EndIf;
	
	If (String.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
		Or String.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")) Then
		
		If ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered")
			Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses") 
			Or ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered") Then
			Return False;
		EndIf;
		
	EndIf;
	
	String.Action = ActionWithDocument;
	If ValueIsFilled(DiscrepancyTreatment) Then
		String.DiscrepancyTreatment = DiscrepancyTreatment;
	EndIf;
	
	If ThereArePropsDueToFaultOfThirdPartyCompany Then
		If ActionWithDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses") Then
			String.ThirdPartyIsGuilty =  ThirdPartyIsGuilty;
		Else
			String.ThirdPartyIsGuilty =  False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Fills in the line details for multi-turn containers
// 
// Parameters:
// 	Form - FormDataStructure - Form to fill in the information
// 	BasisDocuments - DynamicList - Documents from where you need to get information. Must contain:
// 		* ToReturnReusablePackage - Boolean - 
// 		* PackageDepositIsRequired - Boolean - 
//
Procedure FillInDetailsOfMultiTurnContainer(Form, BasisDocuments) Export
	
	CurFoundationDocument = Undefined;
	FoundRow = Undefined;
	For Each RowOfProductsTable In Form.Goods Do
		
		If CurFoundationDocument <> RowOfProductsTable.SaleOfGoodsAndServices Then
			CurFoundationDocument = RowOfProductsTable.SaleOfGoodsAndServices;
			FoundRows = BasisDocuments.FindRows(New Structure("SaleOfGoodsAndServices", CurFoundationDocument));		
			If FoundRows.Count() > 0 Then
				FoundRow = FoundRows[0];
			Else	
				FoundRow = Undefined;
			EndIf;
		EndIf;
		
		If FoundRow <> Undefined Then
			FillInMultiTurnContainerDetailsInLine(RowOfProductsTable, FoundRow);		
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure FillInMultiTurnContainerDetailsInLine(RowOfProductsTable, StringFoundationDocuments) Export
	
	RowOfProductsTable.ToReturnReusablePackage = StringFoundationDocuments.ToReturnReusablePackage;
	RowOfProductsTable.PackageDepositIsRequired 	  = StringFoundationDocuments.PackageDepositIsRequired;	
	
EndProcedure


#EndRegion

