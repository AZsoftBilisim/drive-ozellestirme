#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Values of form details
	CompositionOfSetOfConstantsOfForm    = TMCommonUse.GetStructureOfSetOfConstants(ConstantsSet);
	ExternalParentConstants = SystemSettingsCached.GetStructureOfParentConstants(CompositionOfSetOfConstantsOfForm);
	WorkMode = New Structure;
	
	ExternalParentConstants.Insert("UseObjectsVersioning");
	ExternalParentConstants.Insert("UseDataSynchronization");
	ExternalParentConstants.Insert("UseSeveralWarehouses");
	ExternalParentConstants.Insert("NewOnlineARAPAccounting");
	ExternalParentConstants.Insert("UseDiscountsMarkupsInSales");
	ExternalParentConstants.Insert("ToUseTermsOfSales");
	ExternalParentConstants.Insert("UseProduction");
	ExternalParentConstants.Insert("UseProductionManagement");
	ExternalParentConstants.Insert("UseProductionManagement2_2");
	ExternalParentConstants.Insert("UseOpportunityManagement");
	ExternalParentConstants.Insert("EnterInformationForDeclarationsOfAlcoholicProducts");
	ExternalParentConstants.Insert("UseOrderSupplyWithAssignment");
	ExternalParentConstants.Insert("GenerateFinancialResult");
	ExternalParentConstants.Insert("UseTransferToCustodyWithRightOfSale");
	ExternalParentConstants.Insert("ProvideAgentServicesOnPurchaseToPrincipals");
	ExternalParentConstants.Insert("OptionOfGoodsAssignmentInSales");
	ExternalParentConstants.Insert("UseCustodyDuringPurchase");
	ExternalParentConstants.Insert("Use1COrdersMobileApplication");
	
	WorkMode.Insert("CompositionOfSetOfConstantsOfForm",    New FixedStructure(CompositionOfSetOfConstantsOfForm));
	WorkMode.Insert("ExternalParentConstants", New FixedStructure(ExternalParentConstants));
	
	WorkMode = New FixedStructure(WorkMode);
	
	// Updating the state of the elements
	SetAvailability();
	
	SystemSettingsLocalization.WhenCreatedOnServer_Sales(ThisForm);
	
	CommentaryOnUseOfContractsForCommissionSales = StrTemplate(NStr("vi = '— bật sử dụng tùy chọn ""Bán hàng ký gửi %1""';
																	|ru = '— включена опция ""Комиссионные продажи %1""';
																	|en = '— the ""Consignment sales %1"" option is enabled'; fa = '— the ""Consignment sales %1"" option is enabled';
																	|it = '— inclusa opzione ""Vendite su commissione %1""';
																	|pl = '— włączona jest opcja ""Sprzedaż komisowa %1""';
																	|tr = '— ""Konsinye satışlar %1"" seçeneği etkinleştirildi'"), 
			ConsignmentSalesServer.PostfixCommissionSchemes25());
	
	Items.WarningUseContractsWithCustomersCommissionSales.Title = CommentaryOnUseOfContractsForCommissionSales;
	
	CommissionSComment = StrTemplate(
			NStr("vi = 'Có thể sử dụng tính năng bán hàng ký gửi %1 khi sử dụng thỏa thuận với khách hàng.';
				|ru = 'Возможность осуществления комиссионных продаж %1 доступна при использовании соглашений с клиентами.';
				|en = 'Consignment sales %1 are available if terms of sales are used.'; fa = 'Consignment sales %1 are available if terms of sales are used.';
				|it = 'La possibilità di effettuare vendite su commissione%1 è disponibile quando si utilizzano contratti con i clienti.';
				|pl = 'Możliwość realizacji sprzedaży komisowej %1 jest dostępna przy użyciu kontraktów z nabywcami.';
				|tr = 'İstemci anlaşmaları ile %1 konsinye satış yapılabilmektedir.'"), 
			ConsignmentSalesServer.PostfixCommissionSchemes20());
		Items.CommentUseCommissionForSales.Title = CommissionSComment;
	
	CommissionSComment = StrTemplate(
			NStr("vi = 'Có thể sử dụng tính năng thực hiện bán hàng ký gửi %1 khi sử dụng hợp đồng với khách hàng.';
				|ru = 'Возможность осуществления комиссионных продаж %1 доступна при использовании договоров с клиентами.';
				|en = 'Consignment sales %1 are available if contracts with customers are used.'; fa = 'Consignment sales %1 are available if contracts with customers are used.';
				|it = 'La possibilità di effettuare vendite su commissione%1 è disponibile quando si utilizzano accordi con i clienti.';
				|pl = 'Możliwość realizacji sprzedaży komisowej %1 jest dostępna przy użyciu kontraktów z nabywcami.';
				|tr = 'İstemci sözleşmeleri ile %1 konsinye satış yapılabilmektedir.'"), 
			ConsignmentSalesServer.PostfixCommissionSchemes25());
		Items.CommentUseCommissionWhenSellingWithoutContract.Title = CommissionSComment;
		
	Items.CommissionSalesSelectionMode.ToolTip = ConsignmentSalesServer.HintWhenChoosingVersionOfCommissionTrading();
		
	PartnerSAccessGroupIsAutomaticallyCreatedToSetVisibility();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DefaultValues = New Structure;
	DefaultValues.Insert(Metadata.Constants.TransactionOnRegisterShiftEndClosing.Name
								, PredefinedValue("Enum.TransactionsOnRegisterShiftEndClosing.None"));
								
	SystemSettingsLocalization.WhenReadingOnServer_Sales(ThisObject);
	TMCommonUseClientServer.SaveValuesBeforeChanging(ThisObject);
	
EndProcedure

// The alert handler of the form.
//
// Parameters:
//	EventName - String - is processed only event Zapisnik generated by the administration panels.
//	Parameter   - Structure - contains the names of constants that are subordinate to the changed constant that "triggered" the alert.
//	Source   - String - name of the changed constant that "triggered" the alert.
//
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return; // such events are not processed
	EndIf;
	
	// If it is a changed constant located in a different form and affecting the values of the constants of this form,
	// then we will read the values of the constants and update the elements of this form.
	If WorkMode.ExternalParentConstants.Property(Source)
	 Or (TypeOf(Parameter) = Type("Structure")
	 		And TMCommonUseClientServer.GetSharedKeysOfStructures(
	 			Parameter, WorkMode.ExternalParentConstants).Count() > 0) Then
		
		ThisForm.Read();
		SetAvailability();
		
	EndIf;
	
	If Source = ThisForm Then
		If Parameter.Property("Item") Then
			Attachable_OnChangeAttribute(Parameter.Item, True, True);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseTermsOfSalesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseTermsOfSalesClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure UseSalesOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseCreditNotesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseCustomerCommercialInvoicesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OptionOfGoodsAssignmentInSalesOnChange(Item)
	Attachable_OnChangeAttribute(Item, True);
EndProcedure

&AtClient
Procedure OptionOfGoodsAssignmentInSalesClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure UseSaleByMultipleOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseCustomerInvoicesForSeveralOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseSalesCommissionOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ProvideAgentServicesOnPurchaseToPrincipalsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OptionForSeparatingGoodsServicesAgencySchemeForPurchasesOnChange(Item)
	Attachable_OnChangeAttribute(Item, True);
EndProcedure

&AtClient
Procedure OptionForSeparatingGoodsServicesAgencySchemeForPurchasesClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure UseShipmentWithDeferredTransferOfTitleOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseRequestsForReturnOfGoodsFromCustomersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseSalesOrderApprovalOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseApprovalOfTermsOfSalesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseApprovalOfRequestsForReturnOfGoodsFromCustomersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseRetailSalesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	UpdateAccessToConnectedHardware();
	
	Notify("Write_ConstantsSet", New Structure, "UseRetailSales");
EndProcedure

&AtClient
Procedure UseSeveralCashRegistersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ProvideDiscountsByCalculationInCashReceiptButtonOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure NumberOfDeferredReceiptStorageDaysOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure DoNotCloseSalesOrdersWithoutCompleteShipmentOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure DoNotCloseSalesOrdersWithoutCompletePaymentOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure UseStatusesOfGoodsServicesSalesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseAdvancedFeaturesOfSalesOrderOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseReasonsForSalesOrderCancellationsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseWarehousesInTabularSectionsOfSalesDocumentsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure TheCostOfGoodsWhenEvaluatingTheProfitabilityOfSalesWhenChanging(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure StandardPriceTypeOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure TransactionOnRegisterShiftEndClosingClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure TransactionOnRegisterShiftEndClosingOnChange(Item)
	
	CallbackOnCompletion = New CallbackDescription("TransactionOnRegisterShiftEndClosingOnChangeCompletion", ThisObject);
	If Not RetailSalesClient.RequestConfirmationOfOperationChangesWhenClosingCashierShift(ThisObject, CallbackOnCompletion) Then
		Attachable_OnChangeAttribute(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure TransactionOnRegisterShiftEndClosingStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	TMCommonUseClientServer.SaveValuesBeforeChanging(ThisObject, Items.TransactionOnRegisterShiftEndClosing.Name);
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	ChoiceData.Add(PredefinedValue("Enum.TransactionsOnRegisterShiftEndClosing.CashRegisterReceiptArchiving"));
	ChoiceData.Add(PredefinedValue("Enum.TransactionsOnRegisterShiftEndClosing.DeleteCashRegisterReceipts"));
	
EndProcedure

&AtClient
Procedure UseShipmentProhibitionOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseGiftCardsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseDiscrepancyCertificatesAfterShipmentOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UsingPaymentStagesInSalesWhenChangesAreMade(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure WorkIsExecutedViaSalesRepresentativesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseJobsToSalesRepresentativesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseJobsToSalesRepresentativesClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ItemizeJobsForSalesRepresentativesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseTransferToCustodyWithRightOfSaleOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OrderExecutionModeOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseCertificatesOfDiscrepanciesAfterShipmentForShipmentsOfGoodsToGiverOnChange(Item)
	OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoodsOnChange(Item)
	OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure PrintPaperReceiptOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OnChangeAttribute(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure PartnerSAccessGroupAtAutoCreationOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseAgentServiceSaleOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableSalesOrderVersioning(Command)
	
	Result = New Structure;
	SaveAttributeValue("EnableSalesOrderVersioning", Result);
	
	If Result.Property("VersioningOfCustomerOrdersIsEnabled") Then
		
		If Result.VersioningOfCustomerOrdersIsEnabled Then
			Explanation = NStr("vi = 'Đối với các đơn đặt hàng của khách đã thiết lập phương án quản lý phiên bản ""Quản lý phiên bản khi kết chuyển"".';
								|ru = 'Для заказов клиентов установлен вариант версионирования ""Версионировать при проведении""';
								|en = 'The ""Version on posting"" versioning option is set for sales orders'; fa = 'The ""Version on posting"" versioning option is set for sales orders';
								|it = 'Per gli ordini dei clienti è impostata l''opzione di versionamento ""Versionare alla registrazione""';
								|pl = 'Dla zamówień sprzedaży została ustawiona opcja wersjowania""Wersjować przy zatwierdzeniu""';
								|tr = 'Satış siparişleri için sürüm oluşturma seçeneği ""Kayıt sırasında sürüm oluştur"" olarak ayarlanmıştır.'");
		Else
			Explanation = NStr("vi = 'Đối với đơn hàng của khách đã bật sử dụng quản lý phiên bản';
								|ru = 'Для заказов клиентов версионирование уже было включено';
								|en = 'Versioning was already enabled for sales orders'; fa = 'Versioning was already enabled for sales orders';
								|it = 'Per gli ordini dei clienti il versionamento è già abilitato';
								|pl = 'Dla zamówień sprzedaży wersjowanie już zostało włączone';
								|tr = 'Sürüm oluşturma, satış siparişleri için zaten etkinleştirildi'");
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Đã bật sử dụng quản lý phiên bản';
									|ru = 'Версионирование включено';
									|en = 'Versioning enabled'; fa = 'Versioning enabled';
									|it = 'Il versionamento è abilitato';
									|pl = 'Wersjowanie włączone';
									|tr = 'Sürüm oluşturma etkin'"),, Explanation, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableReturnRequestVersioning(Command)
	
	Result = New Structure;
	SaveAttributeValue("EnableReturnRequestVersioning", Result);
	
	If Result.Property("VersioningOfRefundRequestsIsEnabled") Then
		
		If Result.VersioningOfRefundRequestsIsEnabled Then
			Explanation = NStr("vi = 'Đối với đề nghị trả hàng đã thiết lập phương án quản lý phiên bản ""Quản lý phiên bản khi kết chuyển""';
								|ru = 'Для заявок на возврат установлен вариант версионирования ""Версионировать при проведении""';
								|en = 'The ""Version on posting"" versioning option is set for return requests'; fa = 'The ""Version on posting"" versioning option is set for return requests';
								|it = 'Per le richieste di reso è impostata l''opzione di versionamento ""Versionare alla registrazione""';
								|pl = 'Dla wniosków o zwrot ustawiona opcja wersjowania ""Wersjować przy zatwierdzeniu""';
								|tr = 'İade istekleri için sürüm oluşturma seçeneği ""Kaydetme sırasında sürüm oluştur"" olarak ayarlanmıştır.'");
		Else
			Explanation = NStr("vi = 'Đã bật sử dụng quản lý phiên bản đối với giấy đề nghị trả hàng';
								|ru = 'Дляаявок на возврат версионирование уже было включено';
								|en = 'Versioning is already performed for return requests'; fa = 'Versioning is already performed for return requests';
								|it = 'Per le richieste di reso il versionamento è già abilitato';
								|pl = 'Dla wniosków o zwrot wersjowanie już zostało włączone';
								|tr = 'Sürüm oluşturma, iade istekleri için zaten etkinleştirildi'");
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Đã bật sử dụng quản lý phiên bản';
									|ru = 'Версионирование включено';
									|en = 'Versioning enabled'; fa = 'Versioning enabled';
									|it = 'Il versionamento è abilitato';
									|pl = 'Wersjowanie włączone';
									|tr = 'Sürüm oluşturma etkin'"),, Explanation, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToEnableVersioningAgreements(Command)
	
	Result = New Structure;
	SaveAttributeValue("ToEnableVersioningAgreements", Result);
	
	If Result.Property("AgreementVersioningIsEnabled") Then
		
		If Result.AgreementVersioningIsEnabled Then
			Explanation = NStr("vi = 'Đối với các thỏa thuận với khách hàng, đã đặt phương án quản lý phiên bản ""Quản lý phiên bản khi kết chuyển""';
								|ru = 'Для соглашений с клиентами установлен вариант версионирования ""Версионировать при проведении""';
								|en = 'The ""Version on posting"" versioning option is set for terms of sales'; fa = 'The ""Version on posting"" versioning option is set for terms of sales';
								|it = 'Per gli accordi con i clienti è abilitata l''opzione di versionamento ""Versionare alla registrazione""';
								|pl = 'Dla umów z klientami ustawiona opcja wersjowania ""Wersjować przy zatwierdzeniu""';
								|tr = 'İstemci sözleşmeleri için sürüm oluşturma seçeneği ""Kaydetme sırasında sürüm oluştur"" olarak ayarlanmıştır.'");
		Else
			Explanation = NStr("vi = 'Đối với thỏa thuận với khách hàng, đã bật sử dụng quản lý phiên bản';
								|ru = 'Для соглашений с клиентами версионирование уже было включено';
								|en = 'Versioning was already enabled for terms of sales'; fa = 'Versioning was already enabled for terms of sales';
								|it = 'Per gli accordi con i clienti il versionamento è già abilitato';
								|pl = 'Dla umów z klientami wersjowanie już zostało włączone';
								|tr = 'Sürüm oluşturma, istemci sözleşmeleri için zaten etkinleştirildi'");
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Đã bật sử dụng quản lý phiên bản';
									|ru = 'Версионирование включено';
									|en = 'Versioning enabled'; fa = 'Versioning enabled';
									|it = 'Il versionamento è abilitato';
									|pl = 'Wersjowanie włączone';
									|tr = 'Sürüm oluşturma etkin'"),, Explanation, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignThoseResponsibleForApprovingTheLogisticsConditionsOfSalesDocuments(Command)
	OpenForm("InformationRegister.TaskPerformers.Form.PerformersOfRoleWithAddressingObject", 
		New Structure("MainAddressingObject,Role", 
			Undefined, 
			PredefinedValue("Catalog.PerformerRoles.ApproverSalesLogisticsTerms")));
EndProcedure

&AtClient
Procedure AssignThoseResponsibleForApprovingTheFinancialTermsOfSalesDocuments(Command)
	OpenForm("InformationRegister.TaskPerformers.Form.PerformersOfRoleWithAddressingObject", 
		New Structure("MainAddressingObject,Role", 
			Undefined, 
			PredefinedValue("Catalog.PerformerRoles.ApproverSalesFinancialTerms")));
EndProcedure

&AtClient
Procedure AssignThoseResponsibleForApprovingThePriceConditionsOfSalesDocuments(Command)
	OpenForm("InformationRegister.TaskPerformers.Form.PerformersOfRoleWithAddressingObject", 
		New Structure("MainAddressingObject,Role", 
			Undefined, 
			PredefinedValue("Catalog.PerformerRoles.ApproverSalesPriceTerms")));
EndProcedure

&AtClient
Procedure AssignPersonsResponsibleForReturnRequestApproval(Command)
	OpenForm("InformationRegister.TaskPerformers.Form.PerformersOfRoleWithAddressingObject", 
		New Structure("MainAddressingObject,Role", 
			Undefined, 
			PredefinedValue("Catalog.PerformerRoles.ApproverOfRequestsForReturnOfGoodsFromCustomers")));
EndProcedure

&AtClient
Procedure AssignThoseResponsibleForApprovingCommercialTermsAndConditionsOfSaleDocuments(Command)
		OpenForm("InformationRegister.TaskPerformers.Form.PerformersOfRoleWithAddressingObject", 
		New Structure("MainAddressingObject,Role", 
			Undefined, 
			PredefinedValue("Catalog.PerformerRoles.ApproverSalesCommercialTerms")));
EndProcedure

&AtClient
Procedure OpenSellerSettings(Command)
	
	OpenForm("Catalog.SalesSettingsForUsers.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenObjectPrintSettings(Command)
	OpenForm("InformationRegister.ObjectPrintSettings.ListForm", , ThisForm);
EndProcedure

&AtClient
Procedure OpenLabelAndPriceTagTemplates(Command)
	OpenForm("Catalog.LabelAndPriceTagTemplates.ListForm", , ThisForm);
EndProcedure

&AtClient
Procedure AdditionalColumnOfDocumentPrintFormsOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure AdditionalColumnOfDocumentPrintFormsClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure UseBarcodingOfObjectPrintFormsOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure NameForPrintingItemKindsOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure DisplayDiscountsInPrintFormsOfSalesDocuments(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure DisplayDiscountsInPrintFormsOfSalesDocumentsClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True, ExternalUpdate = False)
	
	If Not ExternalUpdate Then
		SystemSettingsClientLocalization.WhenChangingBankingDetails_Sales(
			Item,
			ThisForm);
	EndIf;
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	SystemSettingsClientLocalization.ProcessingNavigationLinkOf_SaleForm(Item,
		FormattedStringURL, 
		StandardProcessing,
		ThisForm);
		
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

#EndRegion

#Region ServerCall

&AtServer
Procedure UpdateAccessToConnectedHardware()
	
	If ConstantsSet.UseRetailSales Then
		Return;
	EndIf;
	
	Constants.UseExchangeWithOfflinePeripherals.Set(False);
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute,  New Structure);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

#EndRegion

#Region Server

&AtServer
Function SaveAttributeValue(DataPathAttribute, Result)
	
	// Storing the values of the details that are not directly related to the constants (in a one-to-one relationship).
	If DataPathAttribute = "" Then
		Return "";
	EndIf;
	
	// Definition of the constant name.
	ConstantName = "";
	If StrStartsWith(Lower(DataPathAttribute), Lower("ConstantsSet.")) Then
		// If the path to the data of the props is specified through the "Setconstant".
		NameParts = StrSplit(DataPathAttribute, ".");
		ConstantName = NameParts[1];
	Else
		// Defining the name and recording the value of the props in the corresponding constant from the "Setconstant".
		// It is used for those form details that are directly related to constants (in a one-to-one relationship).
		If DataPathAttribute = "EnableSalesOrderVersioning"
			Or DataPathAttribute = "EnableReturnRequestVersioning"
			Or DataPathAttribute = "ToEnableVersioningAgreements" Then
			
			ConstantsSet.UseObjectsVersioning = True;
			ConstantName = "UseObjectsVersioning";
			
		EndIf;
	EndIf;
	
	If DataPathAttribute = "OrderExecutionMode" Then
		
		If OrderExecutionMode = 1 Then
			Constants.UseAdvancedFeaturesOfSalesOrder.Set(True);
			Constants.UseShipmentByRowsInSalesOrder.Set(False);
			ConstantsSet.UseAdvancedFeaturesOfSalesOrder = True;
			ConstantsSet.UseShipmentByRowsInSalesOrder = False;
		ElsIf OrderExecutionMode = 2 Then
			Constants.UseAdvancedFeaturesOfSalesOrder.Set(True);
			Constants.UseShipmentByRowsInSalesOrder.Set(True);
			ConstantsSet.UseAdvancedFeaturesOfSalesOrder = True;
			ConstantsSet.UseShipmentByRowsInSalesOrder = True;
		Else
			Constants.UseAdvancedFeaturesOfSalesOrder.Set(False);
			Constants.UseShipmentByRowsInSalesOrder.Set(False);
			ConstantsSet.UseAdvancedFeaturesOfSalesOrder = False;
			ConstantsSet.UseShipmentByRowsInSalesOrder = False;
		EndIf;
		
		ConstantName = "UseAdvancedFeaturesOfSalesOrder";
		
	EndIf;
	
	// Saving the value of a constant.
	If ConstantName <> "" Then
		ConstantManager = Constants[ConstantName];
		ConstantValue = ConstantsSet[ConstantName];
		
		If ConstantManager.Get() <> ConstantValue Then
			ConstantManager.Set(ConstantValue);
		EndIf;
		
		If SystemSettingsCached.ThereAreSubordinateConstants(ConstantName, ConstantValue) Then
			ThisForm.Read();
		EndIf;
		
	EndIf;
	
	If DataPathAttribute = "EnableSalesOrderVersioning" Then
		
		ObjectsForVersioning = New Map;
		If ConstantsSet.UseSalesOrderApproval Then
			ObjectsForVersioning.Insert("Document.SalesOrder", "VersionizeOnPost");
		EndIf;
		
		Result.Insert("VersioningOfCustomerOrdersIsEnabled",
			TMCommonUse.EnableObjectsVersioning(ObjectsForVersioning));
		SetAvailabilityOfVersioningCustomerOrders();
	EndIf;
	
	If DataPathAttribute = "EnableReturnRequestVersioning" Then
		
		ObjectsForVersioning = New Map;
		If ConstantsSet.UseApprovalOfRequestsForReturnOfGoodsFromCustomers Then
			ObjectsForVersioning.Insert("Document.RequestForReturnOfGoodsFromCustomer", "VersionizeOnPost");
		EndIf;
		
		Result.Insert("VersioningOfRefundRequestsIsEnabled",
			TMCommonUse.EnableObjectsVersioning(ObjectsForVersioning));
		SetAvailabilityOfVersioningOfRefundRequests();
	EndIf;
	
	If DataPathAttribute = "ToEnableVersioningAgreements" Then
		
		ObjectsForVersioning = New Map;
		If ConstantsSet.UseApprovalOfTermsOfSales Then
			ObjectsForVersioning.Insert("Catalog.TermsOfSale", "VersionizeOnWrite");
		EndIf;
		
		Result.Insert("AgreementVersioningIsEnabled",
			TMCommonUse.EnableObjectsVersioning(ObjectsForVersioning));
		SetAvailabilityOfVersioningAgreements();
	EndIf;
	
	SystemSettingsLocalization.SavePropsValue_Sales(ConstantName, ConstantValue, ThisForm);
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseSeveralWarehouses;
		
		Items.UseWarehousesInTabularSectionsOfSalesDocuments.Enabled = ConstantValue;
		Items.GroupCommentUseWarehousesInTheTabularPartOfSalesDocuments.Visible = Not ConstantValue;
		Items.GroupOfThePageCommentCostOfGoodsWhenEvaluatingTheProfitabilityOfSales.CurrentPage = Items.TheGroupCommentsOnTheCostOfGoodsWhenAssessingTheProfitabilityOfSales1;
		
		ConstantValue = ConstantsSet.UseSeveralPriceTypes;
		
		Items.GoodsCostWhenEvaluatingSalesProfitability1.Enabled = ConstantValue;
		Items.GoodsCostWhenEvaluatingSalesProfitability2.Enabled = ConstantValue;
		Items.TheGroupCommentsOnTheCostOfGoodsWhenAssessingTheProfitabilityOfSales.Visible = Not ConstantValue;
		
		Items.DisplayDiscountsInPrintFormsOfSalesDocuments.Enabled =
			Constants.UseDiscountsMarkupsInSales.Get()
			Or Constants.UseDiscountAdjustmentsInSales.Get();
		
		Items.OptionOfGoodsAssignmentInSales.Visible = Constants.UseOrderSupplyWithAssignment.Get()
			And Not GetFunctionalOption("TradeManagement");
		
		ProductionFromTollFreeRawMaterialsIsAvailable = False;
		ProductionFromTollFreeRawMaterialsIsAvailable = True;
		Items.GroupProductionFromTollFreeRawMaterials2_5.Visible = ProductionFromTollFreeRawMaterialsIsAvailable;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTermsOfSales" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.ToUseTermsOfSales;
		UseSalesCommission = ConstantsSet.UseSalesCommission;
		UseCommission20 = Constants.ConsignmentSaleIsUsed20.Get();
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseTermsOfSales,
			ConstantsSet.UseTermsOfSales <> Enums.UseTermsOfSales.DontUse);
		Items.UseApprovalOfTermsOfSales.Enabled = ConstantValue;
		Items.GroupCommentUseCommissionOnSales.Visible = Not ConstantValue
			And Not ConstantsSet.OnlyConsignmentSales25;
		Items.UseSalesCommission.Enabled = ConstantsSet.UseCustomerContracts;
		Items.GroupOptionCommissionSales.Visible = UseSalesCommission
			And ConstantValue And Not ConstantsSet.OnlyConsignmentSales25 And ConstantValue And UseCommission20;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseSalesOrders" Or DataPathAttribute = "" Then
		ConstantValue 						   = ConstantsSet.UseSalesOrders;
		ThereAreExchangesWithFormationOfContractsForOrders =
			Constants.UseDataSynchronization.Get() And DataExchangeTMERP.ThereAreExchangesWithFormationOfContractsForOrders();
		
		Items.UseSaleByMultipleOrders.Enabled 				  = ConstantValue And Not ThereAreExchangesWithFormationOfContractsForOrders;
		Items.UseCustomerInvoicesForSeveralOrders.Enabled 	  = ConstantValue And Not ThereAreExchangesWithFormationOfContractsForOrders;
		Items.GroupCommentUseSaleUnderSeveralOrders.Visible = ThereAreExchangesWithFormationOfContractsForOrders;
	
		Use1COrders = Constants.Use1COrdersMobileApplication.Get();
		WorkIsExecutedViaSalesRepresentatives = ConstantsSet.WorkIsExecutedViaSalesRepresentatives;
		
		AgencyServicesForProcurementByOrders = ConstantsSet.ProvideAgentServicesOnPurchaseToPrincipals 
				And ConstantsSet.OptionOfGoodsAssignmentInSales = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder;
		
		Items.UseSalesOrders.Enabled = 
			Not Use1COrders And Not WorkIsExecutedViaSalesRepresentatives
			And Not AgencyServicesForProcurementByOrders;
				
		Items.GroupCommentUseOrdersWithAgencyPurchases.Visible = AgencyServicesForProcurementByOrders;
		
		Items.GroupCommentUseOrders.Visible = ConstantValue And (Use1COrders Or WorkIsExecutedViaSalesRepresentatives);
		CommentUseOrders = NStr("vi = 'Không thể vô hiệu hóa sử dụng đơn hàng của khách vì';
								|ru = 'Невозможно отключение заказов клиентов, так как';
								|en = 'Cannot disable sales orders as'; fa = 'Cannot disable sales orders as';
								|it = 'Non è possibile disabilitare gli ordini dei clienti perché';
								|pl = 'Niemożliwe jest wyłączenie zamówień sprzedaży, ponieważ';
								|tr = 'Satış siparişleri devre dışı bırakılamıyor çünkü'")
			+ ?(Use1COrders And WorkIsExecutedViaSalesRepresentatives, ": ", " ")
			+ ?(Use1COrders, NStr("vi = 'đã bật đồng bộ hóa dữ liệu với ứng dụng di động ""1C:Order""';
									|ru = 'включена синхронизация данных с мобильным приложением ""1С:Заказы""';
									|en = 'data synchronization with mobile application 1C:Orders is enabled'; fa = 'data synchronization with mobile application 1C:Orders is enabled';
									|it = 'la sincronizzazione dei dati con l''applicazione mobile ""1C:Orders"" è abilitata';
									|pl = 'została włączona synchronizacja danych z aplikacją mobilną ""1C:Orders""';
									|tr = 'mobil uygulama ""1C:Orders"" ile veri senkronizasyonu etkin'"), "")
			+ ?(Use1COrders And WorkIsExecutedViaSalesRepresentatives, ", ", ?(Use1COrders,".", ""))
			+ ?(WorkIsExecutedViaSalesRepresentatives, NStr("vi = 'đã bật quản lý công việc thông qua đại diện thương mại.';
															|ru = 'включено ведение работы через торговых представителей.';
															|en = 'work via sales representatives is enabled.'; fa = 'work via sales representatives is enabled.';
															|it = 'è abilitato lo svolgimento di lavoro tramite i rappresentanti commerciali.';
															|pl = 'zostało włączone prowadzenie prac przez przedstawicieli handlowych.';
															|tr = 'satış temsilcileri aracılığıyla çalışma etkindir.'"), "");
			
		Items.CommentUseOrders.Title = CommentUseOrders;
		
		YouCanUseProvisionOfAgencyServicesWhenPurchasing = (ConstantsSet.OptionOfGoodsAssignmentInSales = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder
			Or ConstantsSet.OptionOfGoodsAssignmentInSales = Enums.OptionsOfGoodsAssignmentInSales.Contract
			Or ConstantsSet.OptionOfGoodsAssignmentInSales.IsEmpty())
			And ConstantsSet.UseCustomerContracts And Constants.UseCustodyDuringPurchase.Get();
			
		Items.GroupCommentUseAgentServicesForPurchasing.Visible = Not YouCanUseProvisionOfAgencyServicesWhenPurchasing;
		Items.ProvideAgentServicesOnPurchaseToPrincipals.Enabled = YouCanUseProvisionOfAgencyServicesWhenPurchasing;
		If Not YouCanUseProvisionOfAgencyServicesWhenPurchasing Then
			ConstantsSet.ProvideAgentServicesOnPurchaseToPrincipals = False;
		EndIf;
		
		YouCanUseCommissionSales = ?(ConstantsSet.OnlyConsignmentSales25,
			ConstantsSet.UseCustomerContracts,
			True);
			
		Items.GroupCanUseCommissionWhenSellingWithoutContract.Visible = Not YouCanUseCommissionSales;
		
		CommissionSComment = StrTemplate(
			NStr("vi = 'Có thể sử dụng tính năng bán hàng ký gửi %1 khi sử dụng hợp đồng với khách hàng.';
				|ru = 'Возможность осуществления комиссионных продаж %1 доступна при использовании договоров с клиентами.';
				|en = 'Consignment sales %1 are available if contracts with customers are used.'; fa = 'Consignment sales %1 are available if contracts with customers are used.';
				|it = 'La possibilità di effettuare vendite su commissione%1 è disponibile quando si utilizzano accordi con i clienti.';
				|pl = 'Możliwość realizacji sprzedaży komisowej %1 jest dostępna przy użyciu kontraktów z nabywcami.';
				|tr = 'oİstemci sözleşmeleri ile %1 konsinye satış yapılabilmektedir.'"), 
			ConsignmentSalesServer.PostfixCommissionSchemes25());
		Items.CommentUseCommissionWhenSellingWithoutContract.Title = CommissionSComment;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseSalesOrders"
	 Or DataPathAttribute = "ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers"
	 Or DataPathAttribute = "ConstantsSet.UseAdvancedFeaturesOfSalesOrder" 
	 Or DataPathAttribute = "OrderExecutionMode"
	 Or DataPathAttribute = "" Then
	 
		UseAdvancedFeaturesOfSalesOrder = ConstantsSet.UseAdvancedFeaturesOfSalesOrder;
		
		Items.UseAdvancedFeaturesOfSalesOrder.Enabled          = ConstantsSet.UseSalesOrders 
																						Or ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers;
		Items.UseApprovalOfRequestsForReturnOfGoodsFromCustomers.Enabled = UseAdvancedFeaturesOfSalesOrder 
																						And ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers;
		Items.UseSalesOrderApproval.Enabled    			  = UseAdvancedFeaturesOfSalesOrder
																						And ConstantsSet.UseSalesOrders;
		
		Items.DoNotCloseSalesOrdersWithoutCompleteShipment.Enabled				  = UseAdvancedFeaturesOfSalesOrder;
		Items.DoNotCloseSalesOrdersWithoutCompletePayment.Enabled				  = UseAdvancedFeaturesOfSalesOrder;
		
		Items.OptionOfGoodsAssignmentInSales.Enabled =
			(ConstantsSet.UseSalesOrders Or ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers)
			And Constants.GenerateFinancialResult.Get();
		
		Items.UseReasonsForSalesOrderCancellations.Enabled = UseAdvancedFeaturesOfSalesOrder;
		Items.UseShipmentByRowsInSalesOrder.Enabled = UseAdvancedFeaturesOfSalesOrder;
		
		OrderExecutionMode = Number(ConstantsSet.UseAdvancedFeaturesOfSalesOrder) + Number(ConstantsSet.UseShipmentByRowsInSalesOrder);
		
		OrderExecutionModeAvailability = ConstantsSet.UseSalesOrders Or ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers;
		
		OrderExecutionModeAvailability = OrderExecutionModeAvailability Or (ConstantsSet.ProvideAgentServicesOnPurchaseToPrincipals 
				And ConstantsSet.OptionOfGoodsAssignmentInSales = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);
		
		Items.OrderExecutionMode.Enabled  = OrderExecutionModeAvailability;
		Items.OrderExecutionMode1.Enabled = OrderExecutionModeAvailability;
		Items.OrderExecutionMode2.Enabled = OrderExecutionModeAvailability;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseSalesOrderApproval"
	 Or DataPathAttribute = "ConstantsSet.UseApprovalOfTermsOfSales"
	 Or DataPathAttribute = "ConstantsSet.UseApprovalOfRequestsForReturnOfGoodsFromCustomers" Or DataPathAttribute = "" Then
		
	 	AvailabilityOfApprovalDetails = 
	 		ConstantsSet.UseSalesOrderApproval 
			Or ConstantsSet.UseApprovalOfTermsOfSales
			Or ConstantsSet.UseApprovalOfRequestsForReturnOfGoodsFromCustomers;
		
		Items.AssignThoseResponsibleForApprovingTheLogisticsConditionsOfSalesDocuments.Enabled 	= AvailabilityOfApprovalDetails;
		Items.AssignThoseResponsibleForApprovingTheFinancialTermsOfSalesDocuments.Enabled 	= AvailabilityOfApprovalDetails;
		Items.AssignThoseResponsibleForApprovingThePriceConditionsOfSalesDocuments.Enabled 		= AvailabilityOfApprovalDetails;
		Items.AssignPersonsResponsibleForReturnRequestApproval.Enabled = ConstantsSet.UseApprovalOfRequestsForReturnOfGoodsFromCustomers;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseObjectsVersioning" Or DataPathAttribute = "" Then
		EstablishAvailabilityOfVersioningOfSalesDocuments();
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseApprovalOfRequestsForReturnOfGoodsFromCustomers" Or DataPathAttribute = "" Then
		Items.AssignPersonsResponsibleForReturnRequestApproval.Enabled = ConstantsSet.UseApprovalOfRequestsForReturnOfGoodsFromCustomers;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTermsOfSales"
		Or DataPathAttribute = "ConstantsSet.UseApprovalOfTermsOfSales" Then
		SetAvailabilityOfVersioningAgreements();
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseSalesOrders"
		Or DataPathAttribute = "ConstantsSet.UseSalesOrderApproval" Then
		SetAvailabilityOfVersioningCustomerOrders();
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers" 
		Or DataPathAttribute = "ConstantsSet.UseApprovalOfRequestsForReturnOfGoodsFromCustomers" Then
		SetAvailabilityOfVersioningOfRefundRequests();
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseRetailSales" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseRetailSales;
		
		Items.TransactionOnRegisterShiftEndClosing.Enabled      = ConstantValue;
		Items.UseGiftCards.Enabled     = ConstantValue;
		Items.NumberOfDeferredReceiptStorageDays.Enabled = ConstantValue;
		Items.UseSeveralCashRegisters.Enabled          = ConstantValue;
		Items.NumberOfArchivedReceiptStorageDays.Enabled = (ConstantValue And ConstantsSet.TransactionOnRegisterShiftEndClosing = Enums.TransactionsOnRegisterShiftEndClosing.CashRegisterReceiptArchiving);
		Items.ProvideDiscountsByCalculationInCashReceiptButton.Enabled       = (ConstantValue And ConstantsSet.UseDiscountsMarkupsInSales);
		Items.PrintPaperReceipt.Enabled				   = ConstantValue;
		
	EndIf;

	If DataPathAttribute = "ConstantsSet.GoodsCostWhenEvaluatingSalesProfitability" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.GoodsCostWhenEvaluatingSalesProfitability;
		If ConstantValue = Enums.GoodsCostWhenEvaluatingSalesProfitability.ByEstimatedCost Then
			Items.TheGroupPageIsTheNormativeViewPrices.CurrentPage = Items.GroupStandardTypeOfPricesGroupByEstimatedCost;
		ElsIf ConstantValue = Enums.GoodsCostWhenEvaluatingSalesProfitability.ByAStandardPriceType Then
			Items.TheGroupPageIsTheNormativeViewPrices.CurrentPage = Items.GroupStandardTypeOfPricesByStandardTypeOfPrices;
		EndIf;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.TransactionOnRegisterShiftEndClosing" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.TransactionOnRegisterShiftEndClosing;
		UseRetailSales = ConstantsSet.UseRetailSales;
		Items.NumberOfArchivedReceiptStorageDays.Enabled = (ConstantValue = Enums.TransactionsOnRegisterShiftEndClosing.CashRegisterReceiptArchiving And UseRetailSales);
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseStatusesOfGoodsServicesSales"
		Or DataPathAttribute = "ConstantsSet.UseCustomerContracts" 
		Or DataPathAttribute = "" Then
	
		ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0 =
			Constants.UseShipmentWithDeferredTransferOfTitle.ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0();
		UseCustomerContracts = ConstantsSet.UseCustomerContracts;
		UseStatusesOfGoodsServicesSales = ConstantsSet.UseStatusesOfGoodsServicesSales;
		
		// The "Use shipment without transfer of ownership" check mark will be available in the following cases:
		// 1. If Contracts with counterparties are not used, but there are sales documents with deferred transfer of ownership 2.0
		// and Statuses of sales are used (when enabled, the FO will be set to use the cargo without transferring ownership rights 2_0)
		// 2. If a clean database is deployed or the database did not work with sales with deferred transfer of ownership, and Contracts with customers are included
		// (when enabled, the FO will be set to use the cargo without transferring ownership rights 2_5)
		// 3. If the database worked with sales with deferred transfer of ownership 2.0, Statuses of implementations and Contracts with counterparties
		// are used (in this case, both FOS will be included: using the load without the transfer of ownership Directors2_0 and using the load without the transfer of ownership Directors2_5)
		// The code of these rules for installing dependent FOS is here: System setup.Synchronize
		// the values of subordinate constants and system setups.Get a table with a dependent constant
		AvailabilityOfShipmentWithoutTransferOfOwnership =
			ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0
				And Not UseCustomerContracts
				And UseStatusesOfGoodsServicesSales
					Or UseCustomerContracts;
			
		Items.UseShipmentWithDeferredTransferOfTitle.Enabled = AvailabilityOfShipmentWithoutTransferOfOwnership;
		Items.TheGroupCanUseTheShipmentWithoutTransferringOwnership.Visible = Not AvailabilityOfShipmentWithoutTransferOfOwnership;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.WorkIsExecutedViaSalesRepresentatives" Or DataPathAttribute = "" Then
		SetAvailability("ConstantsSet.UseSalesOrders");
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseJobsToSalesRepresentatives" Or DataPathAttribute = "" Then
		SetAvailabilityOfTasks();
	EndIf;
	
	If DataPathAttribute = "OrderExecutionMode" Or DataPathAttribute = "" Then
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.OrderExecutionMode,  OrderExecutionMode > 0);
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.OrderExecutionMode1, OrderExecutionMode > 1)
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UsePaymentStepsInSales" Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UsePaymentStepsInSales;
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.SimplifiedScheme, ConstantValue <> Enums.UsePaymentSteps.SimplifiedScheme);
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.CustomSettings, ConstantValue = Enums.UsePaymentSteps.PaymentSchedules);
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseSeveralCashRegisters" Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseSeveralCashRegisters;
		
		If ConstantValue Then
			Items.GroupTheCashierPageOfKKM.CurrentPage = Items.GroupCommentOfSeveralCashRegisters;
		Else
			Items.GroupTheCashierPageOfKKM.CurrentPage = Items.GroupExplanationOneCashRegisterKKM;
		EndIf;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.DisplayAdditionalVATColumns" Or DataPathAttribute = "" Then
		Items.DisplayAdditionalVATColumns.Enabled = ConstantsSet.UseVATAccounting;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.ProvideAgentServicesOnPurchaseToPrincipals"
		Or DataPathAttribute = "ConstantsSet.UseCustomerContracts" 
		Or DataPathAttribute = "ConstantsSet.UseSalesOrders"
		Or DataPathAttribute = "ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers"
		Or DataPathAttribute = "OrderExecutionMode"
		Or DataPathAttribute = "ConstantsSet.OptionOfGoodsAssignmentInSales"
		Or DataPathAttribute = "OptionForSeparatingGoodsServicesAgencySchemeForPurchases"
		Or DataPathAttribute = "ConstantsSet.UseSalesCommission"
		Or DataPathAttribute = "ConstantsSet.SelectConsignmentSalesVersion"
		Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.ProvideAgentServicesOnPurchaseToPrincipals;
		
		SeparationOfGoods = ConstantsSet.OptionOfGoodsAssignmentInSales = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder
				Or ConstantsSet.OptionOfGoodsAssignmentInSales = Enums.OptionsOfGoodsAssignmentInSales.Contract
				Or ConstantsSet.OptionOfGoodsAssignmentInSales.IsEmpty();
		
		YouCanUseOrderSeparation = ConstantsSet.UseSalesOrders
			And Constants.UseOrderSupplyWithAssignment.Get()
			And OrderExecutionMode = 2
			And SeparationOfGoods;
		
		YouCanUseProvisionOfAgencyServicesWhenPurchasing = ConstantsSet.UseCustomerContracts
			And Constants.UseCustodyDuringPurchase.Get()
			And (SeparationOfGoods Or (Not ConstantsSet.UseSalesOrders And Not ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers));
			
		Items.GroupCommentUseAgentServicesForPurchasing.Visible = Not YouCanUseProvisionOfAgencyServicesWhenPurchasing;
		Items.ProvideAgentServicesOnPurchaseToPrincipals.Enabled = YouCanUseProvisionOfAgencyServicesWhenPurchasing;
		
		ConstantValue = ConstantsSet.ProvideAgentServicesOnPurchaseToPrincipals;
		
		If ConstantValue Then
			
			Items.OptionOfGoodsAssignmentInSales.ReadOnly = True;
			Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.Enabled = True;
			
			Items.OptionOfGoodsAssignmentInSales.ChoiceList.Clear();
			Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ChoiceList.Clear();
			
			TextByCustomerOrder = NStr("vi = 'Theo đơn hàng của khách';
										|ru = 'По заказу клиента';
										|en = 'By sales order'; fa = 'By sales order';
										|it = 'Per ordine del cliente';
										|pl = 'Wg zamówienia klienta';
										|tr = 'Satış siparişine göre'");
			TextOfAgreementWithClient = NStr("vi = 'Theo hợp đồng với khách hàng';
											|ru = 'По договору с клиентом';
											|en = 'By contract with customer'; fa = 'By contract with customer';
											|it = 'In base al contratto con il cliente';
											|pl = 'Wg umowy z klientem';
											|tr = 'İstemci sözleşmesine göre'");
			
			If YouCanUseOrderSeparation Then
				Items.OptionOfGoodsAssignmentInSales.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.SalesOrder, TextByCustomerOrder);
				Items.OptionOfGoodsAssignmentInSales.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.Contract, TextByCustomerOrder);
								
				Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.SalesOrder, TextByCustomerOrder);
				Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.Contract, TextOfAgreementWithClient);
				Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ReadOnly = False;
				Items.GroupGoodsPeggingOptionAgencyPurchases.Visible = False;
				Items.GroupCommentOnPeggingWithEnabledAgencyPurchases.Visible = True;
			ElsIf ConstantsSet.UseSalesOrders
				Or ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers Then
				Items.OptionOfGoodsAssignmentInSales.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.Contract, TextByCustomerOrder);
				Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.Contract, TextOfAgreementWithClient);
				Items.GroupGoodsPeggingOptionAgencyPurchases.Visible = True;
				Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ReadOnly = True;
				Items.GroupCommentOnPeggingWithEnabledAgencyPurchases.Visible = True;
			Else
				Items.OptionOfGoodsAssignmentInSales.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.Contract," ");
				Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.Contract, TextOfAgreementWithClient);
				Items.GroupGoodsPeggingOptionAgencyPurchases.Visible = True;
				Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ReadOnly = True;
				Items.GroupCommentOnPeggingWithEnabledAgencyPurchases.Visible = False;
			EndIf;
			
			OrderExecutionModeAvailability = (ConstantsSet.UseSalesOrders 
													Or ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers) 
													And Not (ConstantsSet.OptionOfGoodsAssignmentInSales = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);
			
			Items.OrderExecutionMode.Enabled  = OrderExecutionModeAvailability;
			Items.OrderExecutionMode1.Enabled = OrderExecutionModeAvailability;
			Items.OrderExecutionMode2.Enabled = OrderExecutionModeAvailability;
		Else
			
			Items.OptionOfGoodsAssignmentInSales.ReadOnly = False;
			
			Items.GroupGoodsPeggingOptionAgencyPurchases.Visible = False;
			Items.GroupGoodsPeggingOptionAgencyPurchases.Visible = False;
			Items.GroupCommentOnPeggingWithEnabledAgencyPurchases.Visible = False;
			
			Items.OptionOfGoodsAssignmentInSales.ChoiceList.Clear();
			If Constants.GenerateFinancialResult.Get() Then
				Items.OptionOfGoodsAssignmentInSales.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.LineOfBusiness);
			EndIf;
			Items.OptionOfGoodsAssignmentInSales.ChoiceList.Add(Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);
			
			Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.ChoiceList.Clear();
			Items.OptionForSeparatingGoodsServicesAgencySchemeForPurchases.Enabled = False;
			
			OrderExecutionModeAvailability = ConstantsSet.UseSalesOrders Or ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers;
			
			Items.OrderExecutionMode.Enabled  = OrderExecutionModeAvailability;
			Items.OrderExecutionMode1.Enabled = OrderExecutionModeAvailability;
			Items.OrderExecutionMode2.Enabled = OrderExecutionModeAvailability;
		
		EndIf;
		
		UseCustomerContracts = ConstantsSet.UseCustomerContracts;
		UseAgreements = ConstantsSet.ToUseTermsOfSales;
		UseSalesCommission = ConstantsSet.UseSalesCommission;
		UseCommission20 = Constants.ConsignmentSaleIsUsed20.Get();
		
		Items.UseSalesCommission.Enabled = UseCustomerContracts;
			
		YouCanChooseOptionOfCommissionSales = UseSalesCommission
			And Not ConstantsSet.OnlyConsignmentSales25
			And UseAgreements
			And UseCustomerContracts
			And UseCommission20;
			
		Items.GroupOptionCommissionSales.Visible = YouCanChooseOptionOfCommissionSales;
		
		Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
		Items.GroupCommentUsingOutdatedCommission.Visible = ConstantsSet.SelectConsignmentSalesVersion;
			
		Items.GroupCanUseCommissionWhenSellingWithoutContract.Visible = Not ConstantsSet.UseCustomerContracts;
		
		Items.CommissionSalesSelectionMode.ChoiceList.Clear();
		Items.CommissionSalesSelectionMode.ChoiceList.Add(False, ConsignmentSalesServer.PostfixCommissionSchemes25());
		Items.CommissionSalesSelectionMode.ChoiceList.Add(True, 
					ConsignmentSalesServer.PostfixCommissionSchemes20() + "/" + ConsignmentSalesServer.PostfixCommissionSchemes25());
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseAgentServiceSale" 
		Or DataPathAttribute = "ConstantsSet.UsePurchaseCommission"
		Or DataPathAttribute = "" Then
		
		UseCommissionPurchasesCommentGroupIsVisible = ConstantsSet.UseAgentServiceSale And ConstantsSet.UsePurchaseCommission;
		Items.GroupCommentUseConsignmentPurchases.Visible = UseCommissionPurchasesCommentGroupIsVisible;
		Items.UsePurchaseCommission.Enabled = Not UseCommissionPurchasesCommentGroupIsVisible;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTransferToCustodyWithRightOfSale"
		Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseTransferToCustodyWithRightOfSale;
		
		Items.ActAfterTransferToCustodian.Visible = ConstantValue;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseCustomerContracts"
		Or DataPathAttribute = "ConstantsSet.UseTransferToCustodyWithRightOfSale"
		Or DataPathAttribute = "ConstantsSet.ProvideAgentServicesOnPurchaseToPrincipals"
		Or DataPathAttribute = "ConstantsSet.ToUseTermsOfSales"
		Or DataPathAttribute = "ConstantsSet.UseSalesCommission"
		Or DataPathAttribute = "ConstantsSet.UseShipmentWithDeferredTransferOfTitle"
		Or DataPathAttribute = "ConstantsSet.UseTollManufacturing2_5"
		Or DataPathAttribute = "" Then
		
		ValueOfUseContractsWithCustomersConstant = ConstantsSet.UseCustomerContracts;
		ValueOfResponsibleStorageConstant = ConstantsSet.UseTransferToCustodyWithRightOfSale;
		ValueOfAgencyPurchaseUsageConstant = ConstantsSet.ProvideAgentServicesOnPurchaseToPrincipals;
		ValueOfCommissionSalesConstant = ConstantsSet.UseSalesCommission;
		ValueOfConstantUseShipmentWithoutTransferOfOwnership2_5 = Constants.UseShipmentWithDeferredTransferOfTitle2_5.Get();
		ValueOfConstantOfAcceptanceIntoProcessing = ConstantsSet.UseTollManufacturing2_5;
		CommissionSaleUnderContractsIsUsed = ValueOfCommissionSalesConstant And ValueOfUseContractsWithCustomersConstant;
		
		EditingContractsWithClientsIsAvailable =
			Not ValueOfResponsibleStorageConstant
			And Not ValueOfAgencyPurchaseUsageConstant
			And Not ValueOfConstantUseShipmentWithoutTransferOfOwnership2_5
			And Not ValueOfConstantOfAcceptanceIntoProcessing
			And Not CommissionSaleUnderContractsIsUsed;
		
		Items.UseCustomerContracts.Enabled = EditingContractsWithClientsIsAvailable;
		Items.GroupUseContractsWithCustomersWarning.Visible =
			ValueOfUseContractsWithCustomersConstant
				And Not EditingContractsWithClientsIsAvailable;
		
		CommentText1 = NStr("vi = 'Không thể ngắt sử dụng hợp đồng với khách hàng, như:';
							|ru = 'Невозможно отключение договоров с клиентами, так как:';
							|en = 'It is not possible to disable contracts with customers because:'; fa = 'غیرفعال‌سازی قراردادهای با مشتریان امکان‌پذیر نیست زیرا:';
							|it = 'Невозможно отключение договоров с клиентами, так как:';
							|pl = 'Nie można wyłączyć kontraktów z klientami, ponieważ:';
							|tr = 'İstemcilerle sözleşmeleri devre dışı bırakmak mümkün değildir çünkü:'");
		
		CommentText1 = CommentText1
			+ ?(ValueOfResponsibleStorageConstant,
				Chars.LF + NStr("vi = '- bật sử dụng tùy chọn ""Chuyển đến bảo quản có quyền bán""';
								|ru = '— включена опция ""Передача на ответственное хранение с правом продажи""';
								|en = '— ""VMI fill-up"" is enabled'; fa = '— ""VMI fill-up"" is enabled';
								|it = '— включена опция ""Передача на ответственное хранение с правом продажи""';
								|pl = '— włączona jest opcja ""Przekazanie na depozytowanie z prawem sprzedaży""';
								|tr = '— ""Satış yetkisiyle VMI transferi"" seçeneği etkinleştirildi'"),
				"");
		
		CommentText1 = CommentText1
			+ ?(ValueOfAgencyPurchaseUsageConstant,
				Chars.LF + NStr("vi = '— bật sử dụng tùy chỉnh ""Cung cấp dịch vụ đại lý khi bán hàng""';
								|ru = '— включена опция ""Оказание агентских услуг по продаже""';
								|en = '— the ""Agent sale services delivery"" option is enabled'; fa = '— the ""Agent sale services delivery"" option is enabled';
								|it = '— включена опция ""Оказание агентских услуг по продаже""';
								|pl = '— włączona jest opcja ""Świadczenie usług agencyjnych sprzedaży""';
								|tr = '— ""Satış için acentelik hizmetlerinin sağlanması"" seçeneği etkinleştirildi'"),
				"");
		
		CommentText1 = CommentText1
			+ ?(CommissionSaleUnderContractsIsUsed,
				Chars.LF + Items.WarningUseContractsWithCustomersCommissionSales.Title,
				"");
		
		CommentText1 = CommentText1
			+ ?(ValueOfConstantUseShipmentWithoutTransferOfOwnership2_5,
				Chars.LF + NStr("vi = '— đã bật tùy chọn ""Xuất kho mà chưa chuyển giao quyền sở hữu""';
								|ru = '— включена опция ""Отгрузка без перехода права собственности""';
								|en = '— the ""Shipment with deferred transfer of title of goods"" option is enabled'; fa = '— the ""Shipment with deferred transfer of title of goods"" option is enabled';
								|it = '— the ""Shipment with deferred transfer of title of goods"" option is enabled';
								|pl = '— the ""Shipment with deferred transfer of title of goods"" option is enabled';
								|tr = '- ""Mülkiyet hakkı transferi olmadan sevkiyat"" seçeneği etkinleştirilir'"),
				"");
		CommentText1 = CommentText1
			+ ?(ValueOfConstantOfAcceptanceIntoProcessing,
				Chars.LF + NStr("vi = '- bật sử dụng tùy chọn ""Sản xuất từ nguyên liệu đặt gia công""';
								|ru = '— включена опция ""Производство из давальческого сырья""';
								|en = '— the ""Subcontracting"" check box is selected'; fa = '— the ""Subcontracting"" check box is selected';
								|it = '— включена опция ""Производство из давальческого сырья""';
								|pl = '— jest włączona opcja ""Produkcja z surowców dostarczonych przez właściciela surowców""';
								|tr = '— ""Verilen fason hizmetleri"" seçeneği etkinleştirildi'"),
				"");
		Items.CommentUseContractsWithClientsWarning.Title = CommentText1;
		
	EndIf;
	
	If DataPathAttribute = "" Then
		
		ConstantValue = Constants.UseCustodyDuringPurchase.Get();
		
		Items.ActOfDiscrepanciesAfterShipmentForShipmentsOfGoodsFromStorage.Visible  = ConstantValue;
		
	EndIf;
	If DataPathAttribute = "ConstantsSet.UseProduction"
		Or DataPathAttribute = "ConstantsSet.UseProductionManagement2_2"
		Or DataPathAttribute = "ConstantsSet.NewOnlineARAPAccounting"
		Or DataPathAttribute = "" Then
		
		Items.TheGroupIsReadyToUseProductionFromTollingRawMaterials2_5.Visible =
			Not ConstantsSet.UseProductionManagement2_2
			Or Not ConstantsSet.NewOnlineARAPAccounting;
		
		If Not ConstantsSet.UseProductionManagement2_2
			Or Not ConstantsSet.NewOnlineARAPAccounting Then
			
			TitleTemplate1 = NStr("vi = 'Để sử dụng sản xuất từ nguyên vật liệu gia công, cần bật sử dụng mục:
									|%1';
									|ru = 'Для использования производства из давальческого сырья необходимо включить опции:
									|%1';
									|en = 'To use subcontracting, enable the following options:
									|%1'; fa = 'To use subcontracting, enable the following options:
									|%1';
									|it = 'Для использования производства из давальческого сырья необходимо включить опции:
									|%1';
									|pl = 'To use subcontracting, enable the following options:
									|%1';
									|tr = 'Tedarikçi hammaddelerinden üretimi kullanmak için şu seçenekleri etkinleştirmeniz gerekmektedir:
									|%1'");
			
			Options = New Array;
			If Not ConstantsSet.UseProductionManagement2_2 Then
				If ConstantsSet.UseProductionManagement Then
					Options.Add(NStr("vi = '- ""Sử dụng sản xuất (phiên bản 2.2)"" trong phân hệ ""Danh mục và quản trị"" - ""Sản xuất""';
									|ru = '- ""Использовать производство (версия 2.2)"" в разделе ""НСИ и администрирование"" - ""Производство"".';
									|en = '- Use production (version 2.2) in Master data and settings - Manufacturing.'; fa = '- Use production (version 2.2) in Master data and settings - Manufacturing.';
									|it = '- ""Использовать производство (версия 2.2)"" в разделе ""НСИ и администрирование"" - ""Производство"".';
									|pl = '- Use production (version 2.2) in Master data and settings - Manufacturing.';
									|tr = '- ""Master veri ve yönetim""; ""Üretim"" bölümündeki ""Üretimi kullan (sürüm 2.2)""'"));
				Else
					Options.Add(NStr("vi = '- ""Sử dụng sản xuất"" trong phân hệ ""Danh mục và quản trị"" - ""Sản xuất"".';
									|ru = '- ""Использовать производство"" в разделе ""НСИ и администрирование"" - ""Производство"".';
									|en = '- Use production in Master data and settings - Manufacturing.'; fa = '- Use production in Master data and settings - Manufacturing.';
									|it = '- ""Использовать производство"" в разделе ""НСИ и администрирование"" - ""Производство"".';
									|pl = '- Use production in Master data and settings - Manufacturing.';
									|tr = '- ""Master veri ve yönetim""; ""Üretim"" bölümündeki ""Üretimi kullan""'"));
				EndIf;
			EndIf;
			
			If Not ConstantsSet.NewOnlineARAPAccounting Then
				Options.Add(NStr("vi = '- ""Hạch toán:Online"" trong phân hệ ""Danh mục và quản trị"" - ""Ngân quỹ và hạch toán"".';
								|ru = '- ""Взаиморасчеты: Онлайн"" в разделе ""НСИ и администрирование"" - ""Казначейство и взаиморасчеты"".';
								|en = '- AR/AP accounting: Online in Master data and settings - Treasury and AR/AP accounting.'; fa = '- AR/AP accounting: Online in Master data and settings - Treasury and AR/AP accounting.';
								|it = '- ""Взаиморасчеты: Онлайн"" в разделе ""НСИ и администрирование"" - ""Казначейство и взаиморасчеты"".';
								|pl = '- AR/AP accounting: Online in Master data and settings - Treasury and AR/AP accounting.';
								|tr = '- ""Master veri ve yönetim""; ""Hazine ve alacak/borç muhasebesi"" bölümündeki ""Alacak/borç muhasebesi: Çevrimiçi"".'"));
			EndIf;
			
			Items.CommentUseTollManufacturing2_5.Title =
					StrTemplate(TitleTemplate1, StrConcat(Options, Chars.LF));
			
		EndIf;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTollManufacturing2_5"
		Or DataPathAttribute = "ConstantsSet.UseProductionManagement2_2"
		Or DataPathAttribute = "ConstantsSet.NewOnlineARAPAccounting"
		Or DataPathAttribute = "" Then
		
		UseProductionManagement2_2 = ConstantsSet.UseProductionManagement2_2;
		
		Items.UseTollManufacturing2_5.Enabled =
			UseProductionManagement2_2
			And ConstantsSet.NewOnlineARAPAccounting;
		
		Items.GroupActsOfDivergenceOfGiverHorizontally.Enabled =
			ConstantsSet.UseTollManufacturing2_5;
		
		Items.UseMaterialProviderOrder2_5.Enabled =
			ConstantsSet.UseTollManufacturing2_5;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTollManufacturing2_5"
		Or DataPathAttribute = "ConstantsSet.UseMaterialProviderOrder2_5"
		Or DataPathAttribute = "" Then
		
		ThereAreExchangesWithFormationOfContractsForOrders =
			Constants.UseDataSynchronization.Get()
			And DataExchangeTMERP.ThereAreExchangesWithFormationOfContractsForOrders();
		
		Items.UseStatusesOfMaterialProviderOrders2_5.Enabled =
			ConstantsSet.UseMaterialProviderOrder2_5;
		
		Items.UseReportToMaterialProviderBySeveralOrders2_5.Enabled =
			ConstantsSet.UseMaterialProviderOrder2_5
			And Not ThereAreExchangesWithFormationOfContractsForOrders;
		
		Items.TheCommentGroupUsesTheReportToTheGiverForSeveralOrders2_5.Visible =
			ThereAreExchangesWithFormationOfContractsForOrders;
		
		Items.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Enabled =
			ConstantsSet.UseMaterialProviderOrder2_5;
		
		OptionOfSeparatingGiverSOrder =
			PredefinedValue("Enum.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder");
		
		SelectionLists = New Array;
		SelectionLists.Add(Items.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.ChoiceList);
		SelectionLists.Add(Items.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.ChoiceList);
		
		For Each CurCurrentSelectionList In SelectionLists Do
			
			GiverSOrderValue = CurCurrentSelectionList.FindByValue(OptionOfSeparatingGiverSOrder);
			
			If ConstantsSet.UseMaterialProviderOrder2_5 And GiverSOrderValue = Undefined Then
				CurCurrentSelectionList.Add(OptionOfSeparatingGiverSOrder);
			ElsIf Not ConstantsSet.UseMaterialProviderOrder2_5 And GiverSOrderValue <> Undefined Then
				CurCurrentSelectionList.Delete(GiverSOrderValue);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTollManufacturing2_5"
		Or DataPathAttribute = "ConstantsSet.UseMaterialProviderOrder2_5"
		Or DataPathAttribute = "ConstantsSet.UseStatusesOfMaterialProviderOrders2_5"
		Or DataPathAttribute = "" Then
		
		UseTollManufacturing2_5 =
			ConstantsSet.UseTollManufacturing2_5;
		
		UseStatusesOfMaterialProviderOrders2_5 =
			ConstantsSet.UseStatusesOfMaterialProviderOrders2_5;
		
		Items.DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment2_5.Enabled =
			UseTollManufacturing2_5
			And UseStatusesOfMaterialProviderOrders2_5;
		
		Items.DoNotCloseMaterialProviderOrdersWithoutCompletePayment2_5.Enabled =
			UseTollManufacturing2_5
			And UseStatusesOfMaterialProviderOrders2_5;
		
		Items.GroupCommentControlClosingOfMaterialProviderOrders2_5.Visible =
			UseTollManufacturing2_5
			And Not UseStatusesOfMaterialProviderOrders2_5;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTollManufacturing2_5"
	 Or DataPathAttribute = "ConstantsSet.UseMaterialProviderOrder2_5"
	 Or DataPathAttribute = "ConstantsSet.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered"
	 Or DataPathAttribute = "" Then
		
		If ConstantsSet.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered =
				PredefinedValue("Enum.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder") Then
			
			Items.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Enabled                = False;
			Items.GroupIsOptionForSeparatingProductsWhenTheyAreAcceptedForProcessingComment.Visible = True;
			
		Else
			
			Items.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Enabled =
				ConstantsSet.UseTollManufacturing2_5
				And ConstantsSet.UseMaterialProviderOrder2_5;
			
			Items.GroupIsOptionForSeparatingProductsWhenTheyAreAcceptedForProcessingComment.Visible = False;
			
		EndIf;
		
	EndIf;
	DataExchangeTMERP.SetAvailabilityOfInformationBaseNodeSettings(ThisObject);
	
	WarningOnEditRepresentation(DataPathAttribute);
	
	SystemSettingsLocalization.SetAvailabilityForSale(DataPathAttribute, ThisObject);
EndProcedure

&AtServer
Procedure WarningOnEditRepresentation(DataPathAttribute)
	
	StructureOfConstants = New Structure(
		"UseCustomerContracts,
		|UseWarehousesInTabularSectionsOfSalesDocuments,
		|UseSalesOrders,
		|UseRequestsForReturnOfGoodsFromCustomers,
		|UseSalesCommission,
		|UseShipmentProhibition,
		|UseGiftCards,
		|UseAdvancedFeaturesOfSalesOrder,
		|UseShipmentByRowsInSalesOrder,
		|UseStatusesOfGoodsServicesSales,
		|UseTransferToCustodyWithRightOfSale,
		|UseTollManufacturing2_5,
		|UseMaterialProviderOrder2_5,
		|UseStatusesOfMaterialProviderOrders2_5,
		|UseShipmentWithDeferredTransferOfTitle");
	
	SystemSettingsLocalization.DisplayingWarningWhenEditing_Sales(StructureOfConstants);
	
	For Each KeyAndValue In StructureOfConstants Do
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items[KeyAndValue.Key],
			ConstantsSet[KeyAndValue.Key]);
	EndDo;
	
EndProcedure

&AtServer
Procedure PartnerSAccessGroupIsAutomaticallyCreatedToSetVisibility()
	Items.PartnerSAccessGroupAtAutoCreation.Visible = Constants.AutomaticallyCreatePartnersWhenSendingElectronicReceiptToCustomer.Get();
EndProcedure

#EndRegion

#Region OtherItems

&AtServer
Procedure EstablishAvailabilityOfVersioningOfSalesDocuments()
	SetAvailabilityOfVersioningCustomerOrders();
	SetAvailabilityOfVersioningOfRefundRequests();
	SetAvailabilityOfVersioningAgreements();
EndProcedure

&AtServer
Procedure SetAvailabilityOfVersioningCustomerOrders()
	
	UseObjectVersioning = TMCommonUse.UseObjectVersioning("Document.SalesOrder");
	Items.EnableSalesOrderVersioning.Enabled =
		ConstantsSet.UseSalesOrderApproval
		And (Not ConstantsSet.UseObjectsVersioning
			Or Not UseObjectVersioning);
			
	If Not UseObjectVersioning Then
		Items.EnableSalesOrderVersioning.Title = NStr("vi = 'Bật tính năng quản lý phiên bản';
														|ru = 'Включить версионирование';
														|en = 'Track versions'; fa = 'پیگیری نسخه‌ها';
														|it = 'Abilitare versionamento';
														|pl = 'Włącz wersjonowanie';
														|tr = 'Sürüm oluşturmayı etkinleştir'");
	Else
		Items.EnableSalesOrderVersioning.Title = NStr("vi = 'Đã bật tính năng quản lý phiên bản';
														|ru = 'Версионирование включено';
														|en = 'Versioning enabled'; fa = 'Versioning enabled';
														|it = 'Il versionamento è abilitato';
														|pl = 'Wersjowanie włączone';
														|tr = 'Sürüm oluşturma etkin'");
		Items.EnableSalesOrderVersioning.Font = New Font();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfVersioningOfRefundRequests()
	
	UseObjectVersioning = TMCommonUse.UseObjectVersioning("Document.RequestForReturnOfGoodsFromCustomer");
	Items.EnableReturnRequestVersioning.Enabled =
		ConstantsSet.UseApprovalOfRequestsForReturnOfGoodsFromCustomers
		And (Not ConstantsSet.UseObjectsVersioning
			Or Not UseObjectVersioning);
			
	If Not UseObjectVersioning Then
		Items.EnableReturnRequestVersioning.Title = NStr("vi = 'Bật sử dụng quản lý phiên bản';
														|ru = 'Включить версионирование';
														|en = 'Track versions'; fa = 'پیگیری نسخه‌ها';
														|it = 'Abilitare versionamento';
														|pl = 'Włącz wersjonowanie';
														|tr = 'Sürüm oluşturmayı etkinleştir'");
	Else
		Items.EnableReturnRequestVersioning.Title = NStr("vi = 'Đã bật tính năng quản lý phiên bản';
														|ru = 'Версионирование включено';
														|en = 'Versioning enabled'; fa = 'Versioning enabled';
														|it = 'Il versionamento è abilitato';
														|pl = 'Wersjowanie włączone';
														|tr = 'Sürüm oluşturma etkin'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfVersioningAgreements()
	
	UseObjectVersioning = TMCommonUse.UseObjectVersioning("Catalog.TermsOfSale");
	Items.ToEnableVersioningAgreements.Enabled =
		ConstantsSet.UseApprovalOfTermsOfSales
		And (Not ConstantsSet.UseObjectsVersioning
			Or Not UseObjectVersioning);
			
	If Not UseObjectVersioning Then
		Items.ToEnableVersioningAgreements.Title = NStr("vi = 'Bật sử dụng quản lý phiên bản';
														|ru = 'Включить версионирование';
														|en = 'Track versions'; fa = 'پیگیری نسخه‌ها';
														|it = 'Abilitare versionamento';
														|pl = 'Włącz wersjonowanie';
														|tr = 'Sürüm oluşturmayı etkinleştir'");
	Else
		Items.ToEnableVersioningAgreements.Title = NStr("vi = 'Đã bật tính năng quản lý phiên bản';
														|ru = 'Версионирование включено';
														|en = 'Versioning enabled'; fa = 'Versioning enabled';
														|it = 'Il versionamento è abilitato';
														|pl = 'Wersjowanie włączone';
														|tr = 'Sürüm oluşturma etkin'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfTasks()
	
	Items.ItemizeJobsForSalesRepresentatives.Enabled =
		ConstantsSet.UseJobsToSalesRepresentatives <> Enums.UseJobsToSalesRepresentatives.NotUsed_;
			
EndProcedure

&AtClient
Procedure TransactionOnRegisterShiftEndClosingOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	If QuestionResult = DialogReturnCode.Yes Then
		Attachable_OnChangeAttribute(Items.TransactionOnRegisterShiftEndClosing);
	Else
		ConstantsSet.TransactionOnRegisterShiftEndClosing = TMCommonUseClientServer.GetValueBeforeChange(ThisObject, Items.TransactionOnRegisterShiftEndClosing.Name);
	EndIf;
EndProcedure

#EndRegion

#EndRegion
